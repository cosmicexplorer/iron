module Stable = struct

  open Import_stable

  module Locked = Feature.Stable.Locked

  module Action = struct
    module V1 = struct
      type t =
        { feature_path : Feature_path.V1.t
        }
      [@@deriving bin_io, fields, sexp]

      let to_model t = t
    end

    module Model = V1
  end

  module Reaction = struct
    module V4 = struct
      type t = (Lock_name.V2.t * Locked.V2.t list) list
      [@@deriving bin_io, sexp]

      let of_model m = m
    end

    module V3 = struct
      type t = (Lock_name.V1.t * Locked.V2.t list) list
      [@@deriving bin_io]

      open! Core.Std
      open! Import

      let of_model m =
        List.filter_map (V4.of_model m) ~f:(fun (lock_name, locks) ->
          Option.map (Lock_name.Stable.V1.of_v2 lock_name) ~f:(fun lock -> lock, locks))
      ;;
    end

    module V2 = struct
      type t = (Lock_name.V1.t * Locked.V1.t list) list
      [@@deriving bin_io]

      let of_model m =
        List.map (V3.of_model m) ~f:(fun (lock_name, locks) ->
          lock_name, List.map locks ~f:Locked.V1.of_v2)
      ;;
    end

    module Model = V4
  end
end

include Iron_versioned_rpc.Make
    (struct let name = "get-locked" end)
    (struct let version = 4 end)
    (Stable.Action.V1)
    (Stable.Reaction.V4)

include Register_old_rpc
    (struct let version = 3 end)
    (Stable.Action.V1)
    (Stable.Reaction.V3)

include Register_old_rpc
    (struct let version = 2 end)
    (Stable.Action.V1)
    (Stable.Reaction.V2)

open! Core.Std
open! Import

module Locked   = Feature.Stable.Locked. Model
module Action   = Stable.Action.         Model

module Reaction = struct
  include Stable.Reaction.Model

  let sort t =
    t
    |> List.sort ~cmp:(fun (lock_name1, _) (lock_name2, _) ->
      Lock_name.compare lock_name1 lock_name2)
    |> List.map ~f:(fun (lock_name, locks) ->
      lock_name, List.sort locks ~cmp:(fun (locked1 : Locked.t) locked2 ->
        User_name.compare locked1.by locked2.by))
  ;;
end