# File: learnrestutil.ex
# Author: Mark Bykerk Kauffman
# Date: 2017.03.22

# An·cil·lar·y operations for the Learn Rest Client's Use
defmodule LearnRestUtil, do: (
  def sayhello(), do: (IO.inspect "hello")

  @doc """
  Take a list of dsks,which are maps themselves, and turn the list into a map
  of maps where the key for each dsk map is the id. We're passing in the results
  list from the following:
  %{"results" => [%{"description" => "Internal data source used for associating records that are created for use by the Bb system.",
    "externalId" => "INTERNAL", "id" => "_1_1"},... "id" => "_51_1"}]
  Called with the following:
  dskMap = LearnRestUtil.dsks_to_map(dsks["results"], %{})
    In the spirit of functional programming, this is recursive.
    The first definition returns mapout, the resultant map, when the input is empty.
    The second splits the input into head and tail, makes a small map from the head and
    merges that with the result.
  """
  def dsks_to_map([],mapout), do: (mapout)
  def dsks_to_map([head|tail], mapout), do: (
    map = Map.merge(mapout, %{head["id"] => head } )
    dsks_to_map(tail, map)
  )

) #defmodule LearnRestUtil

LearnRestUtil.sayhello()
IO.inspect LearnRestUtil.dsks_to_map([%{"externalId" => "saml.test.shib", "id" => "_8_1"}, %{"externalId" => "MicrosoftAzureAD", "id" => "_10_1"}],%{})
#Output:
# %{"_10_1" => %{"externalId" => "MicrosoftAzureAD", "id" => "_10_1"},
#   "_8_1" => %{"externalId" => "saml.test.shib", "id" => "_8_1"}}
