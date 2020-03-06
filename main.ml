open Telegram.Api
open Telegram.Api.Chat
open Telegram.Api.User
open Telegram.Api.Command
open Telegram.Api.Message
open Telegram.Api.UserProfilePhotos

type user = unit
type message = unit

module Bot = struct
  type event = NewMessageReceived of user * message
  type cmd = Send of user * string
  type model = unit

  let update model = function NewMessageReceived (_, _) -> (model, [])
end

module MyBot = Telegram.Api.Mk (struct
  include Telegram.BotDefaults

  let token = Sys.getenv "TELEGRAM_TOKEN"

  let commands =
    let open Telegram.Actions in
    let say_hi {chat= {id; _}; _} = send_message ~chat_id:id "Hi"
    and my_pics = function
      | {chat; from= Some {id; _}; _} -> (
          get_user_profile_photos id
          /> function
          | Result.Success photos ->
              send_message ~chat_id:chat.id "Your photos: %d" photos.total_count
          | Result.Failure _ ->
              send_message ~chat_id:chat.id
                "Couldn't get your profile pictures!" )
      | {chat= {id; _}; _} ->
          send_message ~chat_id:id "Couldn't get your profile pictures!"
    and check_admin {chat= {id; _}; _} =
      send_message ~chat_id:id "Congrats, you're an admin!" in
    [ {name= "say_hi"; description= "Say hi!"; enabled= true; run= say_hi}
    ; { name= "my_pics"
      ; description= "Count profile pictures"
      ; enabled= true
      ; run= my_pics }
    ; { name= "admin"
      ; description= "Check whether you're an admin"
      ; enabled= true
      ; run= with_auth ~command:check_admin } ]
end)

let () = MyBot.run ()
