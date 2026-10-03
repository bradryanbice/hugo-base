/* CSS policy for hugo-base and every site that consumes it.
 *
 * This enforces the rules in agents/rules/css.md that a machine can check.
 * It is deliberately a short list: these are policy rules, not a style guide,
 * so formatting and ordering are left alone.
 *
 * The config ships in the module and runs from the version a site pins, so a
 * rule added here reaches a site in the same pull request that bumps
 * hugo-base, next to the migration note that explains how to comply.
 *
 * A legitimate exception is taken with an inline stylelint-disable-next-line
 * comment naming the rule, plus a reason. The base has a few, each marked. */

// Values that are not a token and do not need to be: keywords, system colors
// (which forced colors mode substitutes), and zero.
const COLOR_KEYWORDS = [
  "inherit",
  "initial",
  "unset",
  "revert",
  "transparent",
  "currentColor",
  "none",
  // System colors, required by @media (forced-colors: active).
  "Highlight",
  "HighlightText",
  "Canvas",
  "CanvasText",
  "LinkText",
  "VisitedText",
  "ButtonText",
  "ButtonFace",
  "/^(white|black)$/",
];

const LENGTH_KEYWORDS = [
  "inherit",
  "initial",
  "unset",
  "revert",
  "auto",
  "none",
  "0",
  // em is relative to the element's own font size, which is the right unit for
  // optical adjustments inside text (inline code padding, underline offset).
  "/^-?[0-9.]+em$/",
  "/^[0-9.]+%$/",
  "/^(max|min|clamp|calc)\\(/",
];

export default {
  rules: {
    /* Color is OKLCH, from a token. */
    "color-no-hex": true,
    "color-named": "never",
    "function-disallowed-list": ["rgb", "rgba", "hsl", "hsla", "hwb", "lab", "lch", "color-mix"],
    "scale-unlimited/declaration-strict-value": [
      [
        "/color$/",
        "color",
        "fill",
        "stroke",
        "background",
        "/^margin/",
        "/^padding/",
        "/^gap$/",
        "row-gap",
        "column-gap",
        "/^inset/",
        "border-radius",
        "z-index",
      ],
      {
        ignoreValues: {
          "": LENGTH_KEYWORDS,
          "/color$/": COLOR_KEYWORDS,
          color: COLOR_KEYWORDS,
          fill: COLOR_KEYWORDS,
          stroke: COLOR_KEYWORDS,
          background: [...COLOR_KEYWORDS, "none"],
          "z-index": ["auto", "0"],
        },
        disableFix: true,
      },
    ],

    /* Nothing wins by shouting. */
    "declaration-no-important": true,

    /* Never remove a focus indicator. The foundation provides one global
     * :focus-visible style, so a component has no reason to touch outline. */
    "declaration-property-value-disallowed-list": {
      outline: ["none", "0", "/^0(px|rem|em)?$/"],
      "outline-width": ["0", "/^0(px|rem|em)$/"],
    },

    /* Logical properties, so right to left languages work. */
    "csstools/use-logical": "always",

    /* Keep the layer list in main.css authoritative: a file that invents its
     * own layer breaks the documented order. */
    "at-rule-disallowed-list": ["import"],
  },
  plugins: ["stylelint-declaration-strict-value", "stylelint-use-logical"],
  overrides: [
    {
      // A site may write its own styles in Sass. The policy still applies:
      // colour is still OKLCH, spacing still comes from tokens. Sass variables
      // count as variables to the strict value rule, so $spacing-m passes and
      // a raw 12px does not.
      files: ["**/*.scss"],
      customSyntax: "postcss-scss",
      rules: {
        // Sass's own @use, @forward and @include are not CSS at-rules, and
        // @import is Sass's deprecated include, not the CSS one this rule is
        // about.
        "at-rule-disallowed-list": null,
      },
    },
  ],
};
