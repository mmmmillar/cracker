import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/list
import gleam/option
import gleam/otp/task
import gleam/string_tree

const alphabet_list = [
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
  "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]

pub fn alphabet() -> List(string_tree.StringTree) {
  alphabet_list
  |> list.map(string_tree.from_string)
}

fn permutations(
  list: List(string_tree.StringTree),
  str_len: Int,
) -> List(string_tree.StringTree) {
  case str_len {
    x if x < 0 -> []
    x if x == 0 -> [string_tree.from_string("")]
    1 -> list
    n -> {
      let next_perms = permutations(list, n - 1)
      list
      |> list.flat_map(fn(letter) {
        next_perms
        |> list.map(fn(tail) { string_tree.append_tree(letter, tail) })
      })
    }
  }
}

pub fn count_permutations(str_len: Int) -> Result(Int, String) {
  case str_len {
    x if x < 0 -> Error("count must be non-negative")
    0 -> Ok(1)
    n -> {
      Ok(
        alphabet()
        |> list.map(fn(_letter) {
          task.async(fn() {
            permutations(alphabet(), n - 1)
            |> list.length
          })
        })
        |> list.map(fn(t) { task.await(t, 1_000_000) })
        |> int.sum,
      )
    }
  }
}

pub fn find_password(
  target: BitArray,
  password_length: Int,
) -> Result(String, Nil) {
  case password_length {
    x if x < 0 -> Error(Nil)
    0 -> Error(Nil)
    n ->
      alphabet()
      |> list.map(fn(letter) {
        task.async(fn() {
          permutations(alphabet(), n - 1)
          |> list.map(fn(s) {
            let candidate =
              string_tree.append_tree(letter, s)
              |> string_tree.to_string

            case crypto.hash(crypto.Sha256, bit_array.from_string(candidate)) {
              t if t == target -> {
                option.Some(candidate)
              }
              _ -> option.None
            }
          })
        })
      })
      |> list.map(fn(t) { task.await(t, 1_000_000) })
      |> list.flat_map(fn(l) { l })
      |> list.find_map(fn(o) { option.to_result(o, Nil) })
  }
}
