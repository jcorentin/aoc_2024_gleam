import gleam/float
import gleam/int
import gleam/list
import gleam/string
import party.{type Parser, digits, do, drop, return, string}

pub type Equation {
  Equation(x_a: Int, y_a: Int, x_b: Int, y_b: Int, x_prize: Int, y_prize: Int)
}

pub fn parse(input: String) -> List(Equation) {
  input
  |> string.trim()
  |> string.split("\n\n")
  |> list.map(parse_equation)
}

fn parse_equation(src: String) {
  let assert Ok(equation) = party.go(equation(), src)
  equation
}

fn equation() -> Parser(Equation, e) {
  use <- drop(string("Button A: X+"))
  use x_a <- do(digits())
  use <- drop(string(", Y+"))
  use y_a <- do(digits())
  use <- drop(string("\nButton B: X+"))
  use x_b <- do(digits())
  use <- drop(string(", Y+"))
  use y_b <- do(digits())
  use <- drop(string("\nPrize: X="))
  use x_prize <- do(digits())
  use <- drop(string(", Y="))
  use y_prize <- do(digits())
  let assert Ok(x_a) = int.parse(x_a)
  let assert Ok(y_a) = int.parse(y_a)
  let assert Ok(x_b) = int.parse(x_b)
  let assert Ok(y_b) = int.parse(y_b)
  let assert Ok(x_prize) = int.parse(x_prize)
  let assert Ok(y_prize) = int.parse(y_prize)
  return(Equation(x_a:, y_a:, x_b:, y_b:, x_prize:, y_prize:))
}

type EquationSolution {
  EquationSolution(a: Float, b: Float)
}

fn solve(equation: Equation) -> EquationSolution {
  let x_a = int.to_float(equation.x_a)
  let x_b = int.to_float(equation.x_b)
  let y_a = int.to_float(equation.y_a)
  let y_b = int.to_float(equation.y_b)
  let x_prize = int.to_float(equation.x_prize)
  let y_prize = int.to_float(equation.y_prize)

  let b = {
    { y_prize -. { { x_prize /. x_a } *. y_a } }
    /. { { -1.0 *. x_b /. x_a } *. y_a +. y_b }
  }
  let a = { x_prize -. { b *. x_b } } /. x_a
  EquationSolution(a:, b:)
}

fn is_properly_solved(equation: Equation, solution: EquationSolution) {
  let low_a = float.truncate(solution.a)
  let low_b = float.truncate(solution.b)
  let high_a = low_a + 1
  let high_b = low_b + 1
  let solved =
    [#(low_a, low_b), #(low_a, high_b), #(high_a, low_b), #(high_a, high_b)]
    |> list.find(one_that: fn(solution) {
      let #(a, b) = solution
      a * equation.x_a + b * equation.x_b == equation.x_prize
      && a * equation.y_a + b * equation.y_b == equation.y_prize
      && a >= 0
      && b >= 0
    })
  case solved {
    Ok(#(a, b)) -> #(True, a, b)
    Error(_) -> #(False, 0, 0)
  }
}

fn price(equation: Equation) {
  let solution = solve(equation)
  case is_properly_solved(equation, solution) {
    #(True, a, b) -> a * 3 + b
    #(False, _, _) -> 0
  }
}

pub fn pt_1(input: List(Equation)) {
  input
  |> list.map(price)
  |> int.sum()
}

pub fn pt_2(input: List(Equation)) {
  input
  |> list.map(fn(equation) {
    Equation(
      ..equation,
      x_prize: equation.x_prize + 10_000_000_000_000,
      y_prize: equation.y_prize + 10_000_000_000_000,
    )
  })
  |> list.map(price)
  |> int.sum()
}
