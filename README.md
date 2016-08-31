# Units

Units provides a pair of macros that allow you to quickly create a module that
defines a set of core units for its users to work with. The macros
create documentation attributes, conversion operators and type specs that allow
Dialyzer to detect most incompatible assignments at compile time.

Units adds almost no run-time overhead to your code. The values you work with
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

Note this isn't an SI vs Imperial units thing - kmh is an SI unit, but it's not the
unit we're choosing to work in, which is metres per second.

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

The operators can also be used to convert between 'other' types in a readable way:

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

_>>> Units does not provide run time type checking <<<_

If you really want runtime type checking you should look at 
[Unit Fun](https://hex.pm/packages/unit_fun). However if you're interested in
using [Dialyzer](http://erlang.org/doc/man/dialyzer.html) with the type specs
created by the Units macros to do static analysis, read on.

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

However if you mistakenly wrote:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :kg, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :kg
```

nothing would happen unless you ran Dialyzer, perhaps using the 
[dialyxir](https://hex.pm/packages/dialyxir) mix plugin, in which case you'd
get this response:
