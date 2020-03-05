type user = unit
type message = unit

module Bot = struct
  type event = NewMessageReceived of user * message
  type cmd = Send of user * string
  type model = unit

  let update model = function NewMessageReceived (_, _) -> (model, [])
end

let () = Printf.printf "started"
