import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/http/request
import gleam/http/response
import gleam/otp/actor
import gleam/string_tree
import mist
import web.{type PubSubMessage}
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let assert Ok(pubsub) =
    actor.start(dict.new(), fn(message, clients) {
      case message {
        Subscribe(id, client) -> {
          echo id <> " subscribed"
          clients
          |> dict.insert(id, client)
          |> actor.continue
        }
        // TaskComplete(message) -> {
        //   clients |> list.each(process.send(_, message))
        //   clients |> actor.continue
        // }
      }
    })

  let secret_key_base = wisp.random_string(64)
  let http_handler = web.handle_request(_, pubsub)

  let assert Ok(_) =
    fn(req) {
      case request.path_segments(req) {
        ["task", id] ->
          mist.server_sent_events(
            req,
            response.new(200),
            init: fn() {
              let client = process.new_subject()
              process.send(pubsub, Subscribe(id, client))

              let selector =
                process.new_selector()
                |> process.selecting(client, function.identity)

              actor.Ready(client, selector)
            },
            loop: fn(message, connection, client) {
              case
                mist.send_event(
                  connection,
                  message |> string_tree.from_string |> mist.event,
                )
              {
                // If it succeeds, continue the process
                Ok(_) -> actor.continue(client)
                // If it fails, disconnect the client and stop the process
                Error(_) -> {
                  // process.send(pubsub, Unsubscribe(client))
                  actor.Stop(process.Normal)
                }
              }
            },
          )
        _ -> req |> wisp_mist.handler(http_handler, secret_key_base)
      }
    }
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
