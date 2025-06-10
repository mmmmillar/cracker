import gleam/dynamic/decode

pub type CrackRequest {
  CrackRequest(hash: String, str_len: Int)
}

pub fn crack_request_decoder() -> decode.Decoder(CrackRequest) {
  use hash <- decode.field("hash", decode.string)
  use str_len <- decode.field("str_len", decode.int)
  decode.success(CrackRequest(hash:, str_len:))
}
