open Telegram.Api
open Telegram.Api.Chat
open Telegram.Api.User
open Telegram.Api.Command
open Telegram.Api.Message
open Telegram.Api.UserProfilePhotos

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

open Lwt

let run ?(log=true) () =
    let process = function
      | Result.Success _ -> return ()
      | Result.Failure e ->
        if log && e <> "Could not get head" then (* Ignore spam *)
          Lwt_io.printl e
        else return () in
    let rec loop () =
      MyBot.pop_update ~run_cmds:true () >>= process >>= loop in
    while true do (* Recover from errors if an exception is thrown *)
      try Lwt_main.run @@ loop ()
      with e -> print_endline @@ Printexc.to_string e
    done

let () = run ()
