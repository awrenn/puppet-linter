const PREC = {
    not: 14,
    negation: 13,
    array_splat: 12,
    binary_in: 11,
    regex: 10,
    multiplicative: 9,
    additive: 8,
    shift: 7,
    equality: 6,
    comparative: 5,
    and: 4,
    or: 3,
    assignment: -1,
    ordering: -2,
  },
  not_operators = ["!"],
  negation_operators = ["-"],
  array_splat_operators = ["*"],
  binary_in_operators = ["in"],
  regex_operators = ["=~", "!~"],
  multiplicative_operators = ["*", "/", "%"],
  additive_operators = ["+", "-"],
  shift_operators = ["<<", ">>"],
  equality_operators = ["==", "!="],
  comparative_operators = ["<", "<=", ">", ">="],
  and = ["and"],
  or = ["or"],
  assignment_operators = ["="],
  ordering_operators = ["->", "~>"];
//keywords = [
//  "and",
//  "application",
//  "attr",
//  "case",
//  "component",
//  "consumes",
//  "default",
//  "define",
//  "elsif",
//  "environment",
//  "false",
//  "function",
//  "if",
//  "import",
//  "in",
//  "inherits",
//  "node",
//  "or",
//  "private",
//  "produces",
//  "regexp",
//  "site",
//  "true",
//  "undef",
//  "unit",
//  "unless",
//];

module.exports = grammar({
  name: "puppet",

  externals: ($) => [
    $._heredoc_header,
    $.heredoc_trim_border,
    $._heredoc_end,
    $._heredoc_end_trim,
  ],

  word: ($) => $.identifier,

  extras: ($) => [$._comment, /\s/],

  rules: {
    source_file: ($) => repeat($._statement),

    _statement: ($) =>
      prec.right(choice($._expression, $.resource_declaration)),

    //keyword: ($) => choice(...keywords),

    identifier: ($) =>
      token(
        choice(
          seq(
            optional("$"),
            repeat(seq(/[a-z_][a-z0-9_]*/, token.immediate("::"))),
            /[a-z_][a-z0-9_]*/
          )
        )
      ),
    immediate_identifier: ($) =>
      token.immediate(
        seq(
          optional("$"),
          optional(/[a-z_][a-z0-9_]*/),
          repeat(seq(token.immediate("::"), /[a-z_][a-z0-9_]*a/)),
          /[a-z_][a-z0-9_]*/
        )
      ),
    lower_identifier: ($) =>
      token(
        seq(
          optional("::"),
          token.immediate(repeat1(seq(/[a-z_][a-z0-9_]*/, "::"))),
          /[a-z_][a-z0-9_]*/
        )
      ),

    capital_identifier: ($) =>
      token(seq(/[A-Z]/, token.immediate(/[a-zA-Z_][a-zA-Z0-9_]*/))),

    var_identifier: ($) =>
      token(
        seq(
          "$",
          optional(/[a-z_][a-z0-9_]*/),
          repeat(seq(token.immediate("::"), /[a-z_][a-z0-9_]*a/)),
          /[a-z_][a-z0-9_]*/
        )
      ),

    escape_sequence: ($) =>
      token.immediate(
        seq(
          "\\",
          choice(
            /[^xuU]/,
            /\d{2,3}/,
            /x[0-9a-fA-F]{2,}/,
            /u[0-9a-fA-F]{4}/,
            /U[0-9a-fA-F]{8}/
          )
        )
      ),

    _resource_title: ($) => choice($.string, $.identifier),
    type: ($) =>
      prec.right(
        seq(
          $.capital_identifier,
          optional(
            seq(
              "[",
              choice(
                $.type,
                seq(
                  $._resource_title,
                  repeat(seq(",", $._resource_title)),
                  optional($._resource_title)
                )
              ),
              "]"
            )
          )
        )
      ),

    number: ($) => choice($.integer),
    integer: ($) => /[0-9]+/,

    interpolation_expression: ($) =>
      choice(seq("${", choice($._expression), "}")),

    _string_body: ($) =>
      repeat1(
        choice(
          $.interpolation_expression,
          /\$[^{]/,
          token.immediate(/[^"\n\\$|]+/),
          $.escape_sequence
        )
      ),
    _fixed_string_body: ($) =>
      repeat1(choice(token.immediate(/[^'\n\\|]+/), $.escape_sequence)),

    string: ($) =>
      choice(
        seq('"', optional($._string_body), '"'),
        seq("'", optional($._fixed_string_body), "'")
      ),

    regex: ($) =>
      token(
        prec.left(
          seq(
            "/",
            repeat(choice(token.immediate(/./), token.immediate("\\/"))),
            "/"
          )
        )
      ),

    array: ($) =>
      seq(
        "[",
        optional(
          seq(repeat(seq($._statement, ",")), $._statement, optional(","))
        ),
        "]"
      ),

    hash_pair: ($) => seq($._expression, "=>", $._expression),
    hash: ($) =>
      seq(
        "{",
        optional(
          seq(repeat(seq($.hash_pair, ",")), $.hash_pair, optional(","))
        ),
        "}"
      ),
    bool: ($) => choice("true", "false"),
    undef: ($) => "undef",

    _expression: ($) =>
      prec.right(
        choice(
          prec(2, seq($._expression, choice($.call, $.field, $.index))),
          prec(
            1,
            seq(
              choice(
                $._value,
                $._wrapped_expression,
                $.binary_expression,
                $.include,
                $.case_statement,
                $.if_statement,
                $.unary_expression,
                $._heredoc,
                $.class_definition,
                $.resource_collector
              )
            )
          )
        )
      ),

    _wrapped_expression: ($) => seq("(", $._statement, ")"),

    _resource_binary_expression: ($) =>
      prec.left(
        PREC.ordering,
        seq($._statement, choice(...ordering_operators), $._statement)
      ),

    _binary_expression: ($) => {
      const table = [
        [PREC.binary_in, choice(...binary_in_operators)],
        [PREC.regex, choice(...regex_operators)],
        [PREC.multiplicative, choice(...multiplicative_operators)],
        [PREC.shift, choice(...shift_operators)],
        [PREC.additive, choice(...additive_operators)],
        [PREC.equality, choice(...equality_operators)],
        [PREC.comparative, choice(...comparative_operators)],
        [PREC.and, choice(...and)],
        [PREC.or, choice(...or)],
        [PREC.assignment, choice(...assignment_operators)],
      ];

      return choice(
        ...table.map(([precedence, operator]) =>
          prec.right(
            precedence,
            seq(
              field("left", $._expression),
              field("operator", operator),
              field("right", $._statement)
            )
          )
        )
      );
    },
    binary_expression: ($) =>
      choice($._binary_expression, $._resource_binary_expression),

    unary_expression: ($) => {
      const table = [
        [PREC.not, choice(...not_operators)],
        [PREC.negation, choice(...negation_operators)],
        [PREC.array_splat, choice(...array_splat_operators)],
      ];

      return choice(
        ...table.map(([precedence, operator]) =>
          prec.left(
            precedence,
            seq(field("operator", operator), field("operand", $._expression))
          )
        )
      );
    },

    index: ($) => prec.left(seq(token.immediate("["), $._expression, "]")),

    field: ($) => prec.left(seq(".", $.immediate_identifier)),

    question_switch: ($) => seq($._expression, "?", $.hash),

    // Attempt to parse _values first,
    // before other objects
    _value: ($) =>
      choice(
        $.number,
        $.string,
        $.bool,
        $.undef,
        $.regex,
        $.array,
        $.hash,
        $.question_switch,
        $.type,
        $.identifier
      ),

    default_param_value: ($) => seq("=", prec(3, $._expression)),
    parameter: ($) =>
      seq(optional($.type), $.identifier, optional($.default_param_value)),

    parameter_list: ($) =>
      seq(repeat(seq($.parameter, ",")), $.parameter, optional(",")),

    standard_parameter_list: ($) => seq("(", optional($.parameter_list), ")"),

    class_definition_block: ($) =>
      seq("{", repeat(prec.right($._statement)), "}"),

    class_definition: ($) =>
      seq(
        // Multiple different key words can use the class-style defintion
        field("type", choice("class", "define")),
        seq(
          $.identifier,
          optional($.standard_parameter_list),
          $.class_definition_block
        )
      ),

    resource_attribute: ($) =>
      seq(
        field("key", choice("default", "*", "require", $.identifier)),
        "=>",
        field("value", $._expression),
        optional(",")
      ),
    resource_config: ($) =>
      seq($._expression, ":", repeat($.resource_attribute)),
    resource_block: ($) =>
      choice($.resource_config, repeat1(seq($.resource_config, ";"))),

    _resource_declaration: ($) =>
      prec.right(
        2,
        seq(
          // check to see if its a resource ref first
          choice($._expression, $.type, "class"),
          seq("{", optional($.resource_block), "}")
        )
      ),

    resource_declaration: ($) =>
      field("resource", prec.right($._resource_declaration)),

    include: ($) => seq("include", $.identifier),

    lambda: ($) =>
      seq(
        "|",
        $.parameter_list,
        "|",
        "{",
        optional(repeat(prec.right($._statement))),
        "}"
      ),

    function_parameters: ($) =>
      seq(repeat(seq($._expression, ",")), $._expression, optional(",")),

    call: ($) =>
      // Use right prec to grab lambdas during the call, not as a seperate call
      prec.right(
        seq(
          choice(
            // Some functions allow for no parens, like $foo.each |$baz| {}
            // We need to have either the func($a) syntax, or the above no-params syntax.
            // Each are optional, but at least one must be used
            seq(
              "(",
              field("params", optional($.function_parameters)),
              ")",
              field("lambda", optional($.lambda))
            ),
            field("lambda", $.lambda)
          )
        )
      ),

    // https://puppet.com/docs/puppet/6/lang_collectors.html
    // The collector expression syntax is special :shrug:
    _or: ($) => "or",
    _and: ($) => "and",
    eq: ($) => "==",
    ne: ($) => "!=",
    collector_match_expression: ($) =>
      seq(
        field("field", $.identifier),
        field("operator", choice($.eq, $.ne)),
        field("key", choice($.string, $.bool, $.number, $.type, $.undef))
      ),
    collector_expression: ($) =>
      prec.right(
        choice(
          seq(
            $.collector_expression,
            field("operator", choice(prec(1, $._and), $._or)),
            $.collector_expression
          ),
          $.collector_match_expression
        )
      ),
    resource_collector: ($) => seq($.type, "<|", $.collector_expression, "|>"),
    _comment: ($) => token(/#[^\n]*/),

    //_if_block: ($) => seq("{", repeat(prec.right($._expression)), "}"),
    _if_block: ($) => seq("{", repeat($._statement), "}"),

    if_block: ($) => seq("if", $._expression, $._if_block),
    else_block: ($) => seq("else", $._if_block),

    if_statement: ($) => seq($.if_block, optional($.else_block)),

    case_block: ($) => seq($._expression, ":", "{", repeat($._statement), "}"),

    case_statement: ($) =>
      seq("case", $._expression, "{", repeat($.case_block), "}"),

    heredoc_body: ($) => $._string_body,
    heredoc_fixed_body: ($) => $._string_body,
    heredoc_switches: ($) =>
      seq("/", repeat(choice("$", "n", "r", "t", "s", "L", "u"))),
    heredoc_syntax: ($) => seq(":", /[^)]+/),

    heredoc_interpolate: ($) =>
      seq(
        "@(",
        '"',
        $._heredoc_header,
        '"',
        optional(choice($.heredoc_switches, $.heredoc_syntax)),
        ")",
        optional($.heredoc_body),
        choice($._heredoc_end, $._heredoc_end_trim)
      ),

    heredoc_fixed: ($) =>
      seq(
        "@(",
        $._heredoc_header,
        optional(choice($.heredoc_switches, $.heredoc_syntax)),
        ")",
        optional($.heredoc_fixed_body),
        $.heredoc_trim_border,
        $._heredoc_end
      ),

    _heredoc: ($) => choice($.heredoc_fixed, $.heredoc_interpolate),
  },
});
