//
//  main.swift
//  truthtableswft
//
//  Created by Will Charlton on 03/10/2021.
//

import Foundation
import Covfefe

func intpow(_ i1: Int, _ i2: Int) -> Int {
    if i2 <= 0 {
        return 1
    } else {
        return intpow(i1, i2 - 1) * i1
    }
}

let grammarString = """
<Formula> ::= <Operation>

<Term> ::= <Operation> | <Group> | <Variable>
<Operand> ::= <Variable> | <Group>

<Group> ::= "(" <Term> ")"
<Symbol> ::= "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
<Variable> ::= <Symbol>

<Operation> ::= <OneOp> | <TwoOp>
<OneOp> ::= <EscapedString> <WHITESPACE> <Operand>
<TwoOp> ::= <Operand> <WHITESPACE> <EscapedString> <WHITESPACE> <Operand>

<String> ::= <Symbol> <String> | <Symbol>
<EscapedString> ::= <BACKSLASH> <String>

<BACKSLASH> ::= "\\\\"
<WHITESPACEOP> ::= " "
<WHITESPACE> ::= <WHITESPACEOP> <WHITESPACE> | <WHITESPACEOP>
"""

var variables: [String] = []
var expressions: [String] = []

func insertBefore(item: String, into: inout Array<String>, before: String?) -> String {
    guard (before != nil) else {
        into.append(item)
        return item
    }
    guard into.contains(before!) else {
        into.append(item)
        return item
    }
    
    let index = into.firstIndex(of: before!)!
    into.insert(item, at: index)
    return item
}

func astparser(tree: ParseTree, formula: String, last: String? = nil) {
    var n_last = last
    func recurse(_ rtree: ParseTree) {
        astparser(tree: rtree, formula: formula, last: n_last)
    }
    switch tree.root! {
    case "WHITESPACE":
        break
    case "Group":
        recurse(tree.children![1])
    case "Term", "Formula", "Operand":
        recurse(tree.children![0])
    case "Operation":
        n_last = insertBefore(item: tree.leavesString(formula: formula), into: &expressions, before: last)
        recurse(tree.children![0])
    case "OneOp":
        recurse(tree.children![2])
    case "TwoOp":
        recurse(tree.children![0])
        recurse(tree.children![4])
    case "Variable":
        variables.append(tree.leavesString(formula: formula))
    case let x:
        print("Unrecognised: \(x)")
    }
    
}

func generateBeginning() -> String {
    return "\\begin{tabular}{\(generateTableColls())}"
}

func generateTableColls() -> String {
    return "|" + variables.map {_ in "c"}.joined(separator: "|") + "||" + expressions.dropLast().map {_ in "c"}.joined(separator: "|") + "||c|"
}

func generateHeader() -> String {
    return "\\hline " +  (variables + expressions).map {"$\($0)$"}.joined(separator: " & ") + " \\\\\\hline"
}

func generateRows() -> [String] {
    let num = variables.count
    return (0 ..< intpow(2, num)).map {
        var row = ""
        for i in (0 ..< num).reversed() {
            row += ($0 & intpow(2, i)) != 0 ? "T & " : "F & "
        }
        row += expressions.map {_ in "  "} .joined(separator: "&")
        row += "\\\\"
        return row
    }
}

func generateEnd() -> String {
    return """
    \\hline
    \\end{tabular}
    """
}

func generateText() -> String {
    return ([generateBeginning(), generateHeader()] + generateRows() + [generateEnd()]).joined(separator: "\n")
}

extension ParseTree {
    func leavesString(formula: String) -> String {
        return self.leafs.map {formula[$0]} .reduce("") {$0 + $1}
    }
}

do {
    let grammar = try Grammar(bnf: grammarString, start: "Formula")
    let parser = CYKParser(grammar: grammar)
    guard let formula = CommandLine.arguments.last else {
        print("Invalid Arguments")
        exit(1)
    }
    guard parser.recognizes(formula) else {
        print("Invalid Arguments")
        exit(1)
    }
    
    let ast = try parser.syntaxTree(for: formula)
    astparser(tree: ast, formula: formula)
    print(generateText())
} catch {
    print(error)
    exit(1)
}
