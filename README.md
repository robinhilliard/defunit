# DefUnit

DefUnit provides a pair of macros that allow you to quickly create a module that
defines a set of core units for its users to work with. The macros
create documentation attributes, conversion operators and type specs that allow
Dialyzer to detect most incompatible assignments at compile time.

DefUnit adds almost no run-time overhead to your code. The values you work with
are everyday floats.

#### Example

Create the file _units.ex_:

```elixir
defmodule Unit do

  use DefUnit
  
  @doc_from_operator """
  Convert from other units to core units used for calculations.
  """

  @doc_to_operator """
  Convert from core units used for calculations to other units.
  """
  
  # Units we do our calculations in
  DefUnit.core  "m",        :m,     "SI length"
  DefUnit.core  "kg",       :kg,    "SI mass"
  DefUnit.core  "s",        :s,     "Time"
  DefUnit.core  "m^2",      :m2,    "SI area"
  DefUnit.core  "ms^{-1}",  :ms,    "SI velocity"
  DefUnit.core  "ms^{-2}",  :ms2,   "SI acceleration"
  DefUnit.core  "kgm^{-3}", :kgm3,  "SI density"
  
  # Units we convert to and from core units
  DefUnit.other "feet",     :feet,    0.3048,   :m,   "FPS length and altitude"
  DefUnit.other "kmh^{-1}", :kmh,     0.27777,  :ms,  "Kilometres per hour"
  DefUnit.other "mph",      :mph,     0.44704,  :ms,  "Imperial velocity"
  DefUnit.other "knots",    :knots,   0.514444, :ms,  "Nautical miles per hour"

end
```

Note that core/other isn't an SI vs Imperial units thing - kmh is an SI unit,
but it's not the velocity unit the developer has chosen to work in, which in this case
is metres per second.

DefUnit will create sensible `@doc` and `@typedoc` attributes. If you use 
[Pandoc](http://pandoc.org) with ex_doc on your module by installing Pandoc and adding:
 
```
  config :ex_doc, :markdown_processor, ExDoc.Markdown.Pandoc
```

to your project's config.exs, unit symbols like `kgm^{-3}` will support 
[LaTeX formatting](http://www.personal.ceu.hu/tex/math.htm#scripts) when your documentation
is rendered.

Now in iex:

```elixir
  iex>import Unit
  iex> 65 <~ :knots
  33.43886
  iex> 60 <~ :mph
  26.8224
  iex> 100 <~ :kmh
  27.777
```

All these values are converted to their equivalent 'core' representation, in this
example metres per second. Conversely:

```elixir  
  iex> 33.43886 ~> :knots
  65.0
  iex> 10 ~> :mph
  22.369362920544024
  iex> 10 ~> :kmh
  36.00100802822479
```

The values are assumed to be in 'core' representation and are converted to their
corresponding 'other' unit. The idea of separating units into 'core' and 'other' may
seem arbitrary, but the idea is that the code using the Unit module is easier to
write and reason about if it is working with a consistent set of core units of the 
developer's choosing.

The operators can also be chained to convert between 'other' types in a readable way:

```elixir
  iex> 100 <~ :kmh ~> :mph
  62.13537938439514
```

You can read the above as 'convert 100 from kmh to mph'. But what is this?

```elixir
  iex> 100 <~ :kg ~> :mph
  223.69362920544023
```

Apparently 100 kilograms is 224 miles per hour right? It is worth repeating:

*>>> DefUnit does not provide run time type checking <<<*

If you really want runtime type checking you should look at 
[Unit Fun](https://hex.pm/packages/unit_fun). However if you're interested in
doing static analysis at compile time using [Dialyzer](http://erlang.org/doc/man/dialyzer.html) and the type specs
created by the DefUnit macros, read on.

#### Using Types

Assume we're writing a library of aerodynamics functions. Aerospace uses a mix of units
from FPS, navigation and SI unit systems, and you really don't want to mess up your units
(see [Mars Climate Orbiter](http://www.wired.com/2010/11/1110mars-climate-observer-report/)).

```elixir
defmodule Aero do

  @doc "pressure in standard atmosphere at `alt` feet"
  @spec p(Unit.feet) :: Unit.kgm3
  def p(alt) do
    8.0e-19 * :math.pow(alt, 4)  \
    - 4.0e-14 * :math.pow(alt, 3) \
    + 1.0e-09 * :math.pow(alt, 2) \
    - 4.0e-05 * alt \
    + 1.225
  end
  
  @doc "acceleration due to gravity"
  @spec g() :: Unit.ms2
  def g() do
    9.81
  end
  
  @doc "stall speed given aircraft weight, wing area, max lift and altitude"
  @spec vs(Unit.kg, Unit.m2, float, Unit.feet) :: Unit.ms
  def vs(m, s, cl_max, alt \\ 0.0) do
    :math.sqrt((2.0 * m * g()) / (p(alt) * s * cl_max))
  end
  
end
```

The units defined in the Unit module are available to use in specs for our
aerodynamics functions. If you were calling your library and wanted to be clear
about the units you were using you can write:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :kg, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :knots
```

If you mistakenly write:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :knots, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :knots
```

or perhaps:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :kg, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :kg
```

you will get a dud result. However if you run Dialyzer (the
[dialyxir](https://hex.pm/packages/dialyxir) mix plugin is easy to set up and
use) you'll get warnings similar to this:

```
$ mix dialyzer
Starting Dialyzer
...stuff ommitted
aero.ex:118: The call 'Elixir.Unit':'~>'(float(),'kg') will never return since
the success typing is (number(),'feet' | 'kmh' | 'knots') -> float() and the
contract is 
    ; (ms(),'knots') -> knots()
    ; (ms(),'mph') -> mph()
    ; (ms(),'kmh') -> kmh()
    ; (m(),'feet') -> feet()
 done in 0m1.36s
done (warnings were emitted)
```

[LYSE](http://learnyousomeerlang.com/dialyzer) has a good explanation of Dialyzer, its
history, intent, and what the various warnings mean.

#### More About the Macros

If your 'other' unit refers to an undefined 'core' unit you will get a compile error:

```
== Compilation error on file test/support/def_unit_example.ex ==
** (ArgumentError) Unit 'kmh' refers to unknown core unit 'speeding_bullet'
```

If your conversion between units is more complex (e.g. Farhrenheit to Celcius or live currency
exchange rates) you can replace the conversion ratio in the other macro with a 2-tuple of 
from/to conversion functions:

```elixir
  DefUnit.core  "C", :c, "Temperature in Celcius"
  DefUnit.other "F", :f,
  {
    &((&1 - 32.0) * (5.0 / 9.0)),
    &((&1 * (9.0 / 5.0)) + 32.0)
  },
  :c, "Temperature in Fahrenheit"
```

