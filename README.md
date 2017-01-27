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
  
   @doc_to_operator "to SI"
  @doc_from_operator "from SI"
  
  # Units calculations are done in
  DefUnit.core  "m",                :m,     "SI length"
  DefUnit.core  "m2",               :m2,    "SI area"
  DefUnit.core  "kg",               :kg,    "SI mass"
  DefUnit.core  "kgm<sup>3</sup>",  :kgm3,  "SI density"
  DefUnit.core  "s",                :s,     "Time"
  DefUnit.core  "C",                :c,     "Temperature in Celcius"
  DefUnit.core  "ms<sup>-1</sup>",  :ms,    "SI Velocity"
  DefUnit.core  "ms<sup>-2</sup>",  :ms2,   "SI Acceleration"
  DefUnit.core  "Nm<sup>2</sup>",   :nm2,   "SI Pressure"
  
  # Units we convert to and from core units
  DefUnit.other "feet",             :feet,    0.3048,   :m,   "FPS length and altitude"
  DefUnit.other "kmh<sup>-1</sup>", :kmh,     0.27777,  :ms,  "Kilometres per hour"
  DefUnit.other "mph",              :mph,     0.44704,  :ms,  "Imperial velocity"
  DefUnit.other "knots",            :knots,   0.514444, :ms,  "Nautical miles per hour"

end
```

The idea of core/other is that the code using this module is easier to
write and reason about if calculations are carried out in a consistent set of 'core' units.
Your core units can be whatever suit your purpose - foot/pound/seconds, currencies, or perhaps 
fully-laden-jumbo-jet/oil-rig/emperor-penguins if you're a Discovery Channel researcher. DefUnit will create sensible `@doc` and `@typedoc` attributes.

Now in iex you can try the conversion operators `<~` and `~>`:

```elixir
  iex>import Unit
  iex> 65 <~ :knots
  33.43886
  iex> 60 <~ :mph
  26.8224
  iex> 100 <~ :kmh
  27.777
  iex> 100 <~ :ms
  100
```

The first three values are converted to their equivalent 'core' representation, in this
example metres per second. The last value is already in metre seconds. Conversely:

```elixir  
  iex> 33.43886 ~> :knots
  65.0
  iex> 10 ~> :mph
  22.369362920544024
  iex> 10 ~> :kmh
  36.00100802822479
  iex> 10 ~> :ms
  10
```

takes values which are assumed to be in 'core' representation and converts them to their
corresponding 'other' unit. The operators can also be chained to convert between 'other'
types in a readable way:

```elixir
  iex> 100 <~ :kmh ~> :mph
  62.13537938439514
```

You can read the above as 'convert 100 from kmh to mph'. But what is this?

```elixir
  iex> 100 <~ :kg ~> :mph
  223.69362920544023
```

Apparently 100 kilograms is 224 miles per hour right? It is worth emphasising at this point:

*DefUnit does not provide run time type checking*

If you really want runtime type checking you should look at 
[Unit Fun](https://hex.pm/packages/unit_fun). However if you're interested in
doing static analysis at compile time using [Dialyzer](http://erlang.org/doc/man/dialyzer.html)
and the type specs created by the DefUnit macros, read on.

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
aerodynamics functions (you could also use the macros directly in the Aero module). If you were 
calling your library and wanted to be clear about the units you were using you can write:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :kg, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :knots
```

If you mistakenly write:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :knots, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :knots
```

or perhaps:

```elixir
piper_archer_stall_speed_kts = vs(1157 <~ :m2, 15.8 <~ :m2, 2.1, 0 <~ :feet) ~> :kg
```

you will get a dud result. However if you run Dialyzer (the
[dialyxir](https://hex.pm/packages/dialyxir) mix plugin is easy to set up and
use) on the last example above you'll get a warning similar to this:

```
$ mix dialyzer
... stuff omitted
aero.ex:144: The call 'Elixir.Aero':'<~'(1157,'m2') breaks the contract (f(),'f') -> c()
    ; (lbs(),'lbs') -> kg()
    ; (feet(),'feet') -> m()
    ; (nm2(),'nm2') -> nm2()
    ; (ms2(),'ms2') -> ms2()
    ; (ms(),'ms') -> ms()
    ; (c(),'c') -> c()
    ; (s(),'s') -> s()
    ; (kgm3(),'kgm3') -> kgm3()
    ; (kg(),'kg') -> kg()
    ; (m2(),'m2') -> m2()
    ; (m(),'m') -> m() in the 1st argument
 done in 0m1.44s
done (warnings were emitted)
```

This is saying that there's no way a measurement of area in m<sup>2</sup> can become
the expected measurement of weight in the first argument of `vs()`. Dialyzer can trace much more 
complex stuff than these examples - [LYSE](http://learnyousomeerlang.com/dialyzer)
has a good explanation of Dialyzer, its history, intent, capabilities and what the various
warnings mean.

#### More About the Macros

If your 'other' unit refers to an undefined 'core' unit you will get a compile error:

```
== Compilation error on file test/support/def_unit_example.ex ==
** (ArgumentError) Unit 'kmh' refers to unknown core unit 'speeding_bullet'
```

In case you need direct access to the conversion factors you specified in `DefUnit.other`, the macro creates
a pair of module attributes:

```elixir
@feet_to_m 0.3048
@m_to_feet 3.280839895
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
