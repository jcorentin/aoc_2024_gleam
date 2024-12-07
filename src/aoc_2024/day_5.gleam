import gleam/bool
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

fn is_valid_page_location(page: Page, rest_of_update: Update, rules: RuleSet) {
  let pages_after =
    dict.get(rules, page)
    |> result.unwrap(set.new())
  list.all(rest_of_update, set.contains(pages_after, _))
}

fn is_valid_update(update: Update, rules: RuleSet) -> Bool {
  case update {
    [page, ..rest] ->
      is_valid_page_location(page, rest, rules) && is_valid_update(rest, rules)
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

fn correct_update(
  corrected_update: Update,
  incorrect_update: Update,
  rules: RuleSet,
) {
  case incorrect_update {
    [first_page, ..rest] -> {
      case is_valid_page_location(first_page, rest, rules) {
        True -> correct_update([first_page, ..corrected_update], rest, rules)
        False ->
          correct_update(
            corrected_update,
            list.append(rest, [first_page]),
            rules,
          )
      }
    }
    _ -> corrected_update
  }
}

pub fn pt_2(input: #(RuleSet, List(Update))) {
  let #(rules, updates) = input
  updates
  |> list.filter(fn(update) {
    update
    |> is_valid_update(rules)
    |> bool.negate()
  })
  |> list.map(correct_update([], _, rules))
  |> list.map(middle_page)
  |> int.sum
}
