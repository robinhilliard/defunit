defmodule DefUnitExample do
  @moduledoc """
  SI Units using watts and watt hours for energy
  Includes constants useful for aerodynamics
  
  This is an example of the use of DefUnit
  """
  use DefUnit
  
  @doc_from_operator ~S"""
  Convert from other units to core units used for calculations.
  
  ## Example
  ```
  
  iex> import DefUnitExample
  iex> 12 <~ :feet
  3.6576000000000004
  iex> 12 <~ :feet2
  1.114836
  iex> 65 <~ :knots
  33.43886
  iex> 60 <~ :mph
  26.8224
  iex> 100 <~ :kmh
  27.777
  iex> 0 <~ :f
  -17.77777777777778
  iex> 100 <~ :kmh ~> :mph
  62.13537938439514
  
  ```
  """

  @doc_to_operator ~S"""
  Convert from core units used for calculations to other units.
  
  ## Example
  ```
  
  iex> import DefUnitExample
  iex> 3.6576000000000004 ~> :feet
  12.0
  iex> 1.114836 ~> :feet2
  12.0
  iex> 33.43886 ~> :knots
  65.0
  iex> 10 ~> :mph
  22.369362920544024
  iex> 10 ~> :kmh
  36.00100802822479
  iex>-17.77777777777778 ~> :f
  0.0
  iex> 100 <~ :kmh ~> :mph
  62.13537938439514
  
  ```
  """
  
  # Units we do our calculations in
  DefUnit.core  "m",        :m,     "SI length"
  DefUnit.core  "kg",       :kg,    "SI mass"
  DefUnit.core  "s",        :s,     "Time"
  DefUnit.core  "m^2",      :m2,    "SI area"
  DefUnit.core  "m^3",      :m3,    "SI volume"
  DefUnit.core  "kgm^{-3}", :kgm3,  "SI density"
  DefUnit.core  "ms^{-1}",  :ms,    "SI velocity"
  DefUnit.core  "ms^{-2}",  :ms2,   "SI acceleration"
  DefUnit.core  "kgms^{-2}",:n,     "SI force (Newtons)"
  DefUnit.core  "Nm^{-2}",  :nm2,   "SI pressure"
  DefUnit.core  "W",        :w,     "SI energy use rate (Watt-hours $Js^{-1}$)"
  DefUnit.core  "Wh",       :wh,    "SI energy (Watts)"
  DefUnit.core  "C",        :c,     "Temperature in Celcius"
  
  # Dimensionless coefficients, still treated as core units
  DefUnit.core  "C_l",      :cl,    "Coefficient of lift"
  DefUnit.core  "C_d",      :cd,    "Coefficient of drag"
  DefUnit.core  "RN",       :rn,    "Reynold's Number"
  DefUnit.core  "E",        :e,     "Efficiency"
  
  # Units we convert to and from core units
  DefUnit.other "feet",     :feet,    0.3048,   :m,   "FPS length and altitude"
  DefUnit.other "lbs",      :lbs,     0.453592, :kg,  "FPS mass"
  DefUnit.other "feet^2",   :feet2,   0.092903, :m2,  "FPS area"
  DefUnit.other "feet^3",   :feet3,   0.0283168,:m3,  "FPS volume"
  DefUnit.other "L",        :l,       0.001,    :m3,  "SI litre"
  DefUnit.other "kmh^{-1}", :kmh,     0.27777,  :ms,  "SI velocity"
  DefUnit.other "mph",      :mph,     0.44704,  :ms,  "FPS velocity"
  DefUnit.other "knots",    :knots,   0.514444, :ms,  "Nautical miles per hour"
  DefUnit.other "minutes",  :min,     60,       :s,   "Minute"
  DefUnit.other "hours",    :hours,   3_600,    :s,   "Hour"
  DefUnit.other "G_{earth}",:gearth,  9.81,     :ms2, "Earth acc. due to gravity"
  DefUnit.other "hp",       :hp,      745.7,    :w,   "Horsepower"
  
  # Units with more complex from/to conversion calculations
  DefUnit.other "F", :f,
  {
    &((&1 - 32.0) * (5.0 / 9.0)),
    &((&1 * (9.0 / 5.0)) + 32.0)
  },
  :c, "Temperature in Farhrenheit"
 
end
