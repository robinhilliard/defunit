defmodule DefUnit do
  @moduledoc """
  DefUnit defines macros used to create type specs and documentation
  when working with a "core" set of measurement units, and also defines
  operators to convert them to and from other units.
  
  ## Example
  ```
  
  use DefUnit
  
  @doc_from_operator "documentation for <~ operator"
  @doc_to_operator "documentation for ~> operator"
  
  # Units calculations are done in
  DefUnit.core  "m",        :m,     "SI length"
  DefUnit.core  "kg",       :kg,    "SI mass"
  DefUnit.core  "s",        :s,     "Time"
  DefUnit.core  "C",        :c,     "Temperature in Celcius"
  DefUnit.core  "ms^{-1}",  :ms,    "Metres per second"

  # Units we convert to and from above units
  DefUnit.other "feet",     :feet,    0.3048,   :m,   "FPS length and altitude"
  DefUnit.other "lbs",      :lbs,     0.453592, :kg,  "FPS mass"
  
  # Units with more complex from/to conversion calculations
  DefUnit.other "F", :f,
  {
    &((&1 - 32.0) * (5.0 / 9.0)),
    &((&1 * (9.0 / 5.0)) + 32.0)
  },
  :c, "Temperature in Farhrenheit"
  
  ```
  """
  
  
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__,
      :core_units, accumulate: true
      Module.register_attribute __MODULE__,
      :other_units, accumulate: true
      Module.register_attribute __MODULE__,
      :doc_to_operator, accumulate: false
      Module.register_attribute __MODULE__,
      :doc_from_operator, accumulate: false
    end
  end
  
  
  @doc ~S"""
  Define a 'core' unit.
  
  - `eq` is the short name for the unit used in the typedoc - basic LaTeX formatting is supported
  - `core_type` is the name used in the type spec for this unit
  - `description` is the description used in the typedoc
  
  """
  defmacro core(eq, core_type, description) do
    quote do
      @core_units {unquote(eq), unquote(core_type)}
      @typedoc unquote(description <> " $" <> eq <> "$")
      @type unquote({core_type, [], nil}) :: float
      @doc @doc_from_operator
      @spec unquote({core_type, [], nil}) <~ unquote(core_type) :: unquote({core_type, [], nil})
      def value <~ unquote(core_type) do
        value
      end
    end
  end
  
  
  @doc """
  Define an 'other' unit.
  
  - `eq` is the short name for the unit used in the typedoc - basic LaTeX formatting is supported
  - `other_type` is the name used in the type spec for this unit
  - `ratio` is either a multiplier to convert this unit to the core unit, or a 2-tuple of from/to conversion functions
  - `core_type` is the name of the corresponding core type
  - `description` is the description used in the typedoc
  
  """
  defmacro other(eq, other_type, ratio, core_type, description) do
    name_string = Atom.to_string(other_type)
    core_type_string = Atom.to_string(core_type)
    to_ratio_name = String.to_atom(name_string <> "_to_" <> core_type_string)
    from_ratio_name = String.to_atom(core_type_string <> "_to_" <> name_string)
    
    {from_ratio, from_op} = cond do
      is_number(ratio) ->
        {
          {:@, [], [{from_ratio_name, [], [1.0 / ratio]}]},
          quote do: value * unquote(ratio)
        }
      is_tuple(ratio) ->
        {fn_from, _} = ratio
        {
          {:@, [], [{from_ratio_name, [], [:na]}]},
          quote do: (unquote(fn_from)).(value)
        }
    end
    
    {to_ratio, to_op} = cond do
      is_number(ratio) ->
        {
          {:@, [], [{to_ratio_name, [], [ratio]}]},
          quote do: value / unquote(ratio)
        }
      is_tuple(ratio) ->
        {_, fn_to} = ratio
        {
          {:@, [], [{to_ratio_name, [], [:na]}]},
          quote do: (unquote(fn_to)).(value)
        }
    end
    
    quote do
      if length(for {_, ct} <- @core_units, ct == unquote(core_type), do: ct) == 0 do
        raise ArgumentError,
        message: """
        Unit '#{unquote(other_type)}' refers to unknown core unit '#{unquote(core_type)}'
        """
      end
       
      @other_units {unquote(eq), unquote(other_type), unquote(core_type)}
      @typedoc unquote(description <> " $" <> eq <> "$")
      @type unquote({other_type, [], nil}) :: float
      unquote(to_ratio)
      unquote(from_ratio)
      @spec unquote({other_type, [], nil}) <~ unquote(other_type) :: unquote({core_type, [], nil})
      def value <~ unquote(other_type) do
        unquote(from_op)
      end
      @doc @doc_to_operator
      @spec unquote({core_type, [], nil}) ~> unquote(other_type) :: unquote({other_type, [], nil})
      def value ~> unquote(other_type) do
        unquote(to_op)
      end
    end
  end
  
end