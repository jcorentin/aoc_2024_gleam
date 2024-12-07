import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

type Page =
  Int

type Update =
  List(Page)

type InputRule {
  Rule(before: Page, after: Page)
}

pub type PageRuleSet {
  RuleSet(pages_before: Set(Page), pages_after: Set(Page))
}

type RuleRegistery =
  Dict(Page, PageRuleSet)

fn parse_rule(rule: String) -> InputRule {
  let assert Ok(#(before, after)) =
    rule
    |> string.split_once("|")

  let assert Ok(before) = int.parse(before)
  let assert Ok(after) = int.parse(after)

  Rule(before:, after:)
}

fn add_rule(
  existing_rules: RuleRegistery,
  rule_to_add: InputRule,
) -> RuleRegistery {
  let new_rules =
    dict.upsert(
      in: existing_rules,
      update: rule_to_add.before,
      with: fn(ruleset) {
        case ruleset {
          Some(ruleset) ->
            RuleSet(
              ..ruleset,
              pages_after: set.insert(ruleset.pages_after, rule_to_add.after),
            )
          None ->
            RuleSet(
              pages_before: set.new(),
              pages_after: set.new() |> set.insert(rule_to_add.after),
            )
        }
      },
    )

  dict.upsert(in: new_rules, update: rule_to_add.after, with: fn(ruleset) {
    case ruleset {
      Some(ruleset) ->
        RuleSet(
          ..ruleset,
          pages_before: set.insert(ruleset.pages_before, rule_to_add.before),
        )
      None ->
        RuleSet(
          pages_before: set.new() |> set.insert(rule_to_add.before),
          pages_after: set.new(),
        )
    }
  })
}

fn parse_rules(rules: String) -> RuleRegistery {
  rules
  |> string.split("\n")
  |> list.map(parse_rule)
  |> list.fold(from: dict.new(), with: add_rule)
}

fn parse_update(update: String) -> Update {
  let update = string.split(update, ",")
  let assert Ok(update) =
    list.map(update, int.parse)
    |> result.all()
  update
}

fn parse_updates(updates) -> List(Update) {
  updates
  |> string.split("\n")
  |> list.map(parse_update)
}

pub fn parse(input: String) -> #(RuleRegistery, List(Update)) {
  let assert Ok(#(rules, updates)) =
    input
    |> string.trim
    |> string.split_once("\n\n")

  let rules = parse_rules(rules)
  let updates = parse_updates(updates)

  #(rules, updates)
}

// Could be refactored with TCO
fn is_valid_update(update: Update, rules: RuleRegistery) -> Bool {
  case update {
    [page, ..rest] -> {
      let assert Ok(RuleSet(_, after)) = dict.get(rules, page)
      list.all(rest, set.contains(after, _)) && is_valid_update(rest, rules)
    }
    _ -> True
  }
}

fn middle_page(update: Update) -> Page {
  let middle_idx = list.length(update) / 2
  let #(_, second_part) = list.split(update, middle_idx)
  let assert [middle_page, ..] = second_part
  middle_page
}

pub fn pt_1(input: #(RuleRegistery, List(Update))) {
  let #(rules, updates) = input
  updates
  |> list.filter(is_valid_update(_, rules))
  |> list.map(middle_page)
  |> int.sum()
}

pub fn pt_2(input: #(RuleRegistery, List(Update))) {
  todo as "part 2 not implemented"
}
