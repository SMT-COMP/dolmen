
(* This file is free software, part of dolmen. See file "LICENSE" for more information. *)

(* Type definitions *)
type term = Term.t
type location = ParseLocation.t

type inductive = {
  name : string;
  vars : term list;
  cstrs : (string * term list) list;
  loc : location option;
}

(* Description of statements. *)
type descr =
  | Pack of t list

  | Pop of int
  | Push of int

  | Prove
  | Consequent of term
  | Antecedent of term

  | Include of string
  | Set_logic of string

  | Get_info of string
  | Set_info of string * term option

  | Get_option of string
  | Set_option of string * term option

  | Def of Term.id * term
  | Decl of Term.id * term
  | Inductive of inductive

  | Get_proof
  | Get_unsat_core
  | Get_value of term list
  | Get_assignment
  | Get_assertions

  | Exit

(* Statements are wrapped in a record to have a location. *)
and t = {
  name : string;
  descr : descr;
  attr : term option;
  loc : location option;
}

(* Debug printing *)

let rec pp_descr b = function
  | Pack l ->
    Printf.bprintf b "pack(%d):\n" (List.length l);
    Misc.pp_list ~pp_sep:Buffer.add_char ~sep:'\n' ~pp b l

  | Pop i -> Printf.bprintf b "pop: %d" i
  | Push i -> Printf.bprintf b "push: %d" i

  | Prove -> Printf.bprintf b "Prove"
  | Consequent t -> Printf.bprintf b "consequent: %a" Term.pp t
  | Antecedent t -> Printf.bprintf b "antecedent: %a" Term.pp t

  | Include f -> Printf.bprintf b "include: %s" f
  | Set_logic s -> Printf.bprintf b "set-logic: %s" s

  | Get_info s -> Printf.bprintf b "get-info: %s" s
  | Set_info (s, o) ->
    Printf.bprintf b "set-info: %s <- %a" s (Misc.pp_opt Term.pp) o

  | Get_option s -> Printf.bprintf b "get-option: %s" s
  | Set_option (s, o) ->
    Printf.bprintf b "set-option: %s <- %a" s (Misc.pp_opt Term.pp) o

  | Def (s, t) -> Printf.bprintf b "def: %s = %a" s.Term.name Term.pp t
  | Decl (s, t) -> Printf.bprintf b "decl: %s : %a" s.Term.name Term.pp t
  | Inductive i ->
    Printf.bprintf b "Inductive(%d): %s, %a\n"
      (List.length i.cstrs) i.name
      (Misc.pp_list ~pp_sep:Buffer.add_string ~sep:" " ~pp:Term.pp) i.vars;
    Misc.pp_list ~pp_sep:Buffer.add_string ~sep:"\n"
      ~pp:(fun b (cstr, l) -> Printf.bprintf b "%s: %a" cstr (
          Misc.pp_list ~pp_sep:Buffer.add_string ~sep:" " ~pp:Term.pp
        ) l) b i.cstrs

  | Get_proof -> Printf.bprintf b "get-proof"
  | Get_unsat_core -> Printf.bprintf b "get-unsat-core"
  | Get_value l ->
    Printf.bprintf b "get-value(%d):\n" (List.length l);
    Misc.pp_list ~pp_sep:Buffer.add_string ~sep:"\n" ~pp:Term.pp b l
  | Get_assignment -> Printf.bprintf b "get-assignment"
  | Get_assertions -> Printf.bprintf b "get-assertions"

  | Exit -> Printf.bprintf b "exit"

and pp b = function { descr } ->
  Printf.bprintf b "%a" pp_descr descr

(* Pretty printing *)

let rec print_descr fmt = function
  | Pack l ->
    Format.fprintf fmt "@[<hov 2>pack(%d):@ %a@]" (List.length l)
    (Misc.print_list ~print_sep:Format.fprintf ~sep:"@ " ~print) l

  | Pop i -> Format.fprintf fmt "pop: %d" i
  | Push i -> Format.fprintf fmt "push: %d" i

  | Prove ->
    Format.fprintf fmt "Prove"
  | Consequent t ->
    Format.fprintf fmt "@[<hov 2>consequent:@ %a@]" Term.print t
  | Antecedent t ->
    Format.fprintf fmt "@[<hov 2>antecedent:@ %a@]" Term.print t

  | Include f ->
    Format.fprintf fmt "@[<hov 2>include:@ %s@]" f
  | Set_logic s ->
    Format.fprintf fmt "@[<hov 2>set-logic:@ %s@]" s

  | Get_info s ->
    Format.fprintf fmt "@[<hov 2>get-info:@ %s@]" s
  | Set_info (s, o) ->
    Format.fprintf fmt "@[<hov 2>set-info:@ %s <-@ %a@]"
      s (Misc.print_opt Term.print) o

  | Get_option s ->
    Format.fprintf fmt "@[<hov 2>get-option:@ %s@]" s
  | Set_option (s, o) ->
    Format.fprintf fmt "@[<hov 2>set-option:@ %s <-@ %a@]"
      s (Misc.print_opt Term.print) o

  | Def (s, t) ->
    Format.fprintf fmt "@[<hov 2>def:@ %s =@ %a@]" s.Term.name Term.print t
  | Decl (s, t) ->
    Format.fprintf fmt "@[<hov 2>decl:@ %s :@ %a@]" s.Term.name Term.print t
  | Inductive i ->
    Format.fprintf fmt "@[<hov 2>Inductive(%d) %s@ %a@\n%a@]"
      (List.length i.cstrs) i.name
      (Misc.print_list ~print_sep:Format.fprintf ~sep:"@ " ~print:Term.print) i.vars
      (Misc.print_list ~print_sep:Format.fprintf ~sep:"@\n"
         ~print:(fun fmt (cstr, l) ->
             Format.fprintf fmt "%s: %a" cstr (
               Misc.print_list ~print_sep:Format.fprintf ~sep:"@ " ~print:Term.print
           ) l)) i.cstrs

  | Get_proof -> Format.fprintf fmt "get-proof"
  | Get_unsat_core -> Format.fprintf fmt "get-unsat-core"
  | Get_value l ->
    Format.fprintf fmt "@[<hov 2>get-value(%d):@ %a@]" (List.length l)
      (Misc.print_list ~print_sep:Format.fprintf ~sep:"@ " ~print:Term.print) l
  | Get_assignment -> Format.fprintf fmt "get-assignment"
  | Get_assertions -> Format.fprintf fmt "get-assertions"

  | Exit -> Format.fprintf fmt "exit"

and print fmt = function { descr } ->
  Format.fprintf fmt "%a" print_descr descr


(* Attributes *)
let attr = Term.const ~ns:Term.Attr

let annot = Term.apply

(* Internal shortcut. *)
let mk ?(name="") ?loc ?attr descr = { name; descr; loc; attr; }

(* Push/Pop *)
let pop ?loc i = mk ?loc (Pop i)
let push ?loc i = mk ?loc (Push i)

(* Assumptions and fact checking *)
let prove ?loc () = mk ?loc Prove
let antecedent ?loc ?attr t = mk ?loc ?attr (Antecedent t)
let consequent ?loc ?attr t = mk ?loc ?attr (Consequent t)

(* Options statements *)
let set_logic ?loc s = mk ?loc (Set_logic s)

let get_info ?loc s = mk ?loc (Get_info s)
let set_info ?loc (s, t) = mk ?loc (Set_info (s, t))

let get_option ?loc s = mk ?loc (Get_option s)
let set_option ?loc (s, t) = mk ?loc (Set_option (s, t))

(* Declarations, i.e given identifier has given type *)
let decl ?loc s ty = mk ?loc (Decl (Term.id Term.Term s, ty))

(* Definitions, i.e given identifier, with arguments,
   is equal to given term *)
let def ?loc s t = mk ?loc (Def (Term.id Term.Term s, t))

(* Inductive types, i.e polymorphic variables, and
   a list of constructors. *)
let inductive ?loc name vars cstrs =
  mk ?loc (Inductive {name; vars; cstrs; loc; })

let data ?loc l = mk ?loc (Pack l)

(* Return values *)
let get_proof ?loc () = mk ?loc Get_proof
let get_unsat_core ?loc () = mk ?loc Get_unsat_core
let get_value ?loc l = mk ?loc (Get_value l)
let get_assignment ?loc () = mk ?loc Get_assignment
let get_assertions ?loc () = mk ?loc Get_assertions

(* End statement *)
let exit ?loc () = mk ?loc Exit




(* Dimacs wrapper *)
let clause ?loc l =
  let t = Term.or_ ?loc l in
  antecedent ?loc t

(* Smtlib wrappers *)
let check_sat = prove
let assert_ ?loc t = antecedent ?loc t

let type_decl ?loc s n =
  let ty = Term.fun_ty ?loc (Misc.replicate n Term.tType) Term.tType in
  mk ?loc (Decl (Term.id Term.Sort s, ty))

let fun_decl ?loc s l t' =
  let ty = Term.fun_ty ?loc l t' in
  mk ?loc (Decl (Term.id Term.Term s, ty))

let type_def ?loc s args body =
  let t = Term.lambda args body in
  mk ?loc (Def (Term.id Term.Sort s, t))

let fun_def ?loc s args ty_ret body =
  let t = Term.lambda args (Term.colon body ty_ret) in
  mk ?loc (Def (Term.id Term.Term s, t))


(* Wrappers for Zf *)
let definition ?loc s ty term =
  let t = Term.colon term ty in
  def ?loc s t

let rewrite ?loc ?attr t = antecedent ?loc ?attr t

let assume ?loc ?attr t = antecedent ?loc ?attr t

let goal ?loc ?attr t =
  mk ?loc ?attr (Pack [
      consequent t;
      prove ();
    ])


(* Wrappers for tptp *)
let include_ ?loc s l =
  let attr = Term.apply ?loc Term.and_t l in
  mk ?loc ~attr (Include s)

let tptp ?loc ?annot name_t role t =
  let aux t =
    match annot with
    | None -> t
    | Some t' -> Term.colon t t'
  in
  let attr = aux (Term.const ~ns:Term.Attr role) in
  let name =
    match name_t with
    | { Term.term = Term.Symbol s } -> Some s.Term.name
    | _ -> None
  in
  let descr = match role with
    | "axiom"
    | "hypothesis"
    | "definition"
    | "lemma"
    | "theorem"
      -> Antecedent t
    | "assumption"
    | "conjecture"
      -> Pack [
          push 1;
          consequent ~attr:(Term.false_) t;
          prove ();
          pop 1;
          antecedent ~attr:(Term.true_) t;
         ]
    | "negated_conjecture"
      -> Pack [
          push 1;
          antecedent ~attr:(Term.false_) t;
          prove ();
          pop 1;
          antecedent ~attr:(Term.true_) (Term.not_ t);
        ]
    | "type"
      -> begin match t with
          | { Term.term = Term.Colon ({ Term.term = Term.Symbol s }, ty )} ->
            Decl (s, ty)
          | _ ->
            Format.eprintf "WARNING: unexpected type declaration@.";
            Pack []
        end
    | "plain"
    | "unknown"
    | "fi_domain"
    | "fi_functors"
    | "fi_predicates"
      -> Pack []
    | _ ->
      Format.eprintf "WARNING: unknown tptp formula role: '%s'@." role;
      Pack []
  in
  mk ?name ?loc ~attr descr

let tpi = tptp
let thf = tptp
let tff = tptp
let fof = tptp
let cnf = tptp



