import gleam/function
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder

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

fn is_valid_equation(
  equation: Equation,
  operators: List(fn(Int, Int) -> Int),
) -> Bool {
  case equation.operands {
    [a, ..] if a > equation.test_value -> False
    [a, b, ..rest] ->
      operators
      |> yielder.from_list()
      |> yielder.map(fn(operator) {
        is_valid_equation(
          Equation(..equation, operands: [operator(a, b), ..rest]),
          operators,
        )
      })
      |> yielder.any(function.identity)
    [a] -> a == equation.test_value
    _ -> False
  }
}

fn sum_valid_test_values(equations: List(Equation), operators) {
  equations
  |> list.filter(is_valid_equation(_, operators))
  |> list.map(fn(eq) { eq.test_value })
  |> int.sum()
}

pub fn pt_1(input: List(Equation)) {
  let operators = [int.multiply, int.add]
  sum_valid_test_values(input, operators)
}

fn concatenate(a: Int, b: Int) -> Int {
  let assert Ok(a) = int.digits(a, 10)
  let assert Ok(b) = int.digits(b, 10)
  let assert Ok(result) =
    list.append(a, b)
    |> int.undigits(10)
  result
}

pub fn pt_2(input: List(Equation)) {
  let operators = [int.multiply, int.add, concatenate]
  sum_valid_test_values(input, operators)
}
