import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Equation {
  Equation(test_value: Int, operands: List(Int))
}

fn parse_equation(equation: String) -> Equation {
  let assert Ok(#(test_value, operands)) = string.split_once(equation, ":")
  let assert Ok(test_value) = int.parse(test_value)

  let assert Ok(operands) =
    operands
    |> string.trim()
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all()

  Equation(test_value:, operands:)
}

pub fn parse(input: String) -> List(Equation) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(parse_equation)
}

fn equation_combinations(operands: List(Int)) -> List(Int) {
  case operands {
    [a, b, ..rest] ->
      list.append(
        equation_combinations([a * b, ..rest]),
        equation_combinations([a + b, ..rest]),
      )
    [a] -> [a]
    _ -> [0]
  }
}

fn is_valid_equation(equation: Equation) -> Bool {
  list.contains(equation_combinations(equation.operands), equation.test_value)
}

pub fn pt_1(input: List(Equation)) {
  input
  |> list.filter(is_valid_equation)
  |> list.map(fn(eq) { eq.test_value })
  |> int.sum()
}

pub fn pt_2(input: List(Equation)) {
  todo as "part 2 not implemented"
}
