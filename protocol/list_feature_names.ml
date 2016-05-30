module Stable = struct

  open Import_stable

  module Action = struct
    module V1 = struct
      type t =
        { feature_path : Feature_path.V1.t option
        ; depth        : int
        ; use_archived : bool
        }
      [@@deriving bin_io, fields, sexp]

      let to_model t = t
    end
  end

  module Reaction = struct
    module V1 = struct
      type t = Feature_path.V1.t list
      [@@deriving bin_io, sexp]

      let of_model t = t
    end
  end
end

include Iron_versioned_rpc.Make
    (struct let name = "list-feature-names" end)
    (struct let version = 1 end)
    (Stable.Action.V1)
    (Stable.Reaction.V1)

module Action   = Stable.Action.V1
module Reaction = Stable.Reaction.V1