defmodule DefUnit do
  @moduledoc """
  Macros used by modules declaring units
  
  ## Example
  ```
  
  use DefUnit
  
  @doc_from_operator ~S"doc for <~ operator"
  @doc_to_operator ~S"doc for ~> operator"
  
  # Units calculations are done in
  DefUnit.core  "m",        :m,     "SI length"
  DefUnit.core  "kg",       :kg,    "SI mass"
  DefUnit.core  "s",        :s,     "Time"

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
  Does this work?
  """
  defmacro core(eq, name, description) do
    quote do
      @core_units {unquote(eq), unquote(name)}
      @typedoc unquote(description <> " $" <> eq <> "$")
      @type unquote({name, [], nil}) :: float
      @doc @doc_from_operator
      @spec unquote({name, [], nil}) <~ unquote(name) :: unquote({name, [], nil})
      def value <~ unquote(name) do
        value
      end
    end
  end
  
  
  @doc """
  
  """
  defmacro other(eq, name, ratio, core_type, description) do
    name_string = Atom.to_string(name)
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
        Unit '#{unquote(name)}' refers to unknown core unit '#{unquote(core_type)}'
        """
      end
       
      @other_units {unquote(eq), unquote(name), unquote(core_type)}
      @typedoc unquote(description <> " $" <> eq <> "$")
      @type unquote({name, [], nil}) :: float
      unquote(to_ratio)
      unquote(from_ratio)
      @spec unquote({name, [], nil}) <~ unquote(name) :: unquote({core_type, [], nil})
      def value <~ unquote(name) do
        unquote(from_op)
      end
      @doc @doc_to_operator
      @spec unquote({core_type, [], nil}) ~> unquote(name) :: unquote({name, [], nil})
      def value ~> unquote(name) do
        unquote(to_op)
      end
    end
  end
  
end