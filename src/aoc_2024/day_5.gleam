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

type RuleSet =
  Dict(Page, Set(Page))

fn parse_rule(rule: String) -> InputRule {
  let assert Ok(#(before, after)) =
    rule
    |> string.split_once("|")

  let assert Ok(before) = int.parse(before)
  let assert Ok(after) = int.parse(after)

  Rule(before:, after:)
}

fn add_rule(rule_set: RuleSet, new_rule: InputRule) -> RuleSet {
  use pageset <- dict.upsert(in: rule_set, update: new_rule.before)
  case pageset {
    Some(pageset) -> set.insert(pageset, new_rule.after)
    None -> set.new() |> set.insert(new_rule.after)
  }
}

fn parse_rules(rules: String) -> RuleSet {
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

pub fn parse(input: String) -> #(RuleSet, List(Update)) {
  let assert Ok(#(rules, updates)) =
    input
    |> string.trim()
    |> string.split_once("\n\n")

  let rules = parse_rules(rules)
  let updates = parse_updates(updates)

  #(rules, updates)
}

// Could be refactored with TCO
fn is_valid_update(update: Update, rules: RuleSet) -> Bool {
  case update {
    [page, ..rest] -> {
      let pages_after =
        dict.get(rules, page)
        |> result.unwrap(set.new())
      list.all(rest, set.contains(pages_after, _))
      && is_valid_update(rest, rules)
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

pub fn pt_1(input: #(RuleSet, List(Update))) {
  let #(rules, updates) = input
  updates
  |> list.filter(is_valid_update(_, rules))
  |> list.map(middle_page)
  |> int.sum()
}

pub fn pt_2(input: #(RuleSet, List(Update))) {
  todo as "part 2 not implemented"
}
