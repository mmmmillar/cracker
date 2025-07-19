import crack_request.{crack_request_decoder}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http.{Get, Post}
import gleam/string_tree
import wisp.{type Request, type Response}

pub type PubSubMessage {
  Subscribe(id: String, client: Subject(String))
  // TaskComplete(String)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn handle_request(req: Request, pubsub: Subject(PubSubMessage)) -> Response {
  use req <- middleware(req)

  case req.method, wisp.path_segments(req) {
    Get, [] -> wisp.html_response(string_tree.from_string("Hello"), 200)
    Post, ["crack"] -> {
      use json <- wisp.require_json(req)
      case decode.run(json, crack_request_decoder()) {
        Ok(crack_request) -> {
          // process.send(pubsub, Publish(message))

          wisp.ok()
        }
        Error(_) -> wisp.unprocessable_entity()
      }
    }
    _, _ -> wisp.not_found()
  }
}
