(************************************************************************)

(*         *   The Coq Proof Assistant / The Coq Development Team       *)
(*  v      *   INRIA, CNRS and contributors - Copyright 1999-2018       *)
(* <O___,, *       (see CREDITS file for the list of authors)           *)
(*   \VV/  **************************************************************)
(*    //   *    This file is distributed under the terms of the         *)
(*         *     GNU Lesser General Public License Version 2.1          *)
(*         *     (see LICENSE file for the text of the license)         *)
(************************************************************************)

(************************************************************************)
(* Coq Language Server Protocol                                         *)
(* Copyright 2019 MINES ParisTech -- LGPL 2.1+                          *)
(* Copyright 2019-2023 Inria -- LGPL 2.1+                               *)
(* Written by: Emilio J. Gallego Arias                                  *)
(************************************************************************)

module Pp = JCoq.Pp
module Ast = JCoq.Ast
module Lang = JLang

module Config = struct
  module Unicode_completion = struct
    type t = [%import: Fleche.Config.Unicode_completion.t]

    let to_yojson = function
      | Off -> `String "off"
      | Internal_small -> `String "internal"
      | Normal -> `String "normal"
      | Extended -> `String "extended"

    let of_yojson (j : Yojson.Safe.t) : (t, string) Result.t =
      match j with
      | `String "off" -> Ok Off
      | `String "internal" -> Ok Internal_small
      | `String "normal" -> Ok Normal
      | `String "extended" -> Ok Extended
      | _ ->
        Error
          "Fleche.Config.Unicode_completion.t: expected one of \
           [off,normal,extended]"
  end

  type t = [%import: Fleche.Config.t] [@@deriving yojson]
end

module Progress = struct
  module Info = struct
    type t = [%import: Fleche.Progress.Info.t] [@@deriving yojson]
  end

  type t =
    { textDocument : Doc.VersionedTextDocument.t
    ; processing : Info.t list
    }
  [@@deriving yojson]
end

let mk_progress ~uri ~version processing =
  let textDocument = { Doc.VersionedTextDocument.uri; version } in
  let params = Progress.to_yojson { Progress.textDocument; processing } in
  Base.mk_notification ~method_:"$/coq/fileProgress" ~params

module Message = struct
  type 'a t =
    { range : JLang.Range.t option
    ; level : int
    ; text : 'a
    }
  [@@deriving yojson]

  let _map ~f { range; level; text } =
    let text = f text in
    { range; level; text }
end

module GoalsAnswer = struct
  type 'pp t =
    { textDocument : Doc.VersionedTextDocument.t
    ; position : Lang.Point.t
    ; goals : 'pp JCoq.Goals.reified_pp option
    ; messages : 'pp Message.t list
    ; error : 'pp option [@default None]
    }
  [@@deriving to_yojson]
end

(** Pull Diagnostics *)
module CompletionStatus = struct
  type t =
    { status : [ `Yes | `Stopped | `Failed ]
    ; range : Lang.Range.t
    }
  [@@deriving yojson]
end

module RangedSpan = struct
  type t =
    { range : Lang.Range.t
    ; span : Ast.t option [@default None]
    }
  [@@deriving yojson]
end

module FlecheDocument = struct
  type t =
    { spans : RangedSpan.t list
    ; completed : CompletionStatus.t
    }
  [@@deriving yojson]
end
