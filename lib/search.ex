defmodule Onvif.Search do
  @moduledoc """
  Interface for making requests to the Onvif search service

  https://www.onvif.org/ver10/search.wsdl
  """
  import Onvif.ApiUtils, only: [search_request: 4]
  import SweetXml
  import XmlBuilder

  alias Onvif.Search.{FindEvents, FindRecordings}

  @doc """
  FindEvents starts a search session, looking for recording events (in the scope that matches the search filter defined in the request).

  Results from the search are acquired using the `get_event_search_results/2` request, specifying the search token returned from this request.

  The device shall continue searching until one of the following occurs:
    * The entire time range from StartPoint to EndPoint has been searched through.
    * The total number of matches has been found, defined by the MaxMatches parameter.
    * The session has been ended by a client EndSession request.
    * The session has been ended because KeepAliveTime since the last request related to this session has expired.

  Results shall be ordered by time, ascending in case of forward search, or descending in case of backward search.
  This operation is mandatory to support for a device implementing the recording search service.
  """
  @spec find_events(Onvif.Device.t(), FindEvents.t()) :: {:ok, String.t()} | {:error, any()}
  def find_events(device, find_events) do
    body = element(:"s:Body", [FindEvents.encode(find_events)])
    search_request(device, "FindEvents", body, &parse_find_token_response/1)
  end

  @doc """
  FindRecordings starts a search session, looking for recordings that matches the scope (See 20.2.4) defined in the request.

  Results from the search are acquired using the GetRecordingSearchResults request, specifying the search token returned from this request.
  The device shall continue searching until one of the following occurs:
    * The entire time range from StartPoint to EndPoint has been searched through.
    * The total number of matches has been found, defined by the MaxMatches parameter.
    * The session has been ended by a client EndSession request.
    * The session has been ended because KeepAliveTime since the last request related to this session has expired.

  The order of the results is undefined, to allow the device to return results in any order they are found.
  This operation is mandatory to support for a device implementing the recording search service.
  """
  @spec find_recordings(Onvif.Device.t(), FindRecordings.t()) ::
          {:ok, String.t()} | {:error, any()}
  def find_recordings(device, find_recordings) do
    body = element(:"s:Body", [FindRecordings.encode(find_recordings)])
    search_request(device, "FindRecordings", body, &parse_find_token_response/1)
  end

  defp parse_find_token_response(xml_response_body) do
    search_token =
      xml_response_body
      |> parse(namespace_conformant: true, quiet: true)
      |> xpath(
        ~x"//tse:SearchToken/text()"s
        |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
        |> add_namespace("tse", "http://www.onvif.org/ver10/search/wsdl")
      )

    {:ok, search_token}
  end
end
