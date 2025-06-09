import argv
import gleam/bit_array
import gleam/list
import permute_strings

pub fn hex_to_bit_array(hex_string: String) -> Result(BitArray, Nil) {
  case bit_array.base16_decode(hex_string) {
    Ok(bits) -> Ok(bits)
    Error(_) -> Error(Nil)
  }
}

pub fn main() {
  // let assert Ok(hash) = argv.load().arguments |> list.first

  let hash = "4f31fa50e5bd5ff45684e560fc24aeee527a43739ab611c49c51098a33e2b469"

  let assert Ok(hash_bits) = case bit_array.base16_decode(hash) {
    Ok(hash_bits) -> Ok(hash_bits)
    Error(_) ->
      Error("Could not decode hash " <> hash <> "- check hash is base16")
  }

  case hash_bits |> permute_strings.find_password(4) {
    Ok(match) -> echo "Password is " <> match
    _ -> echo "No match found!"
  }
}
