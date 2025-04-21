defmodule Onvif.Search do
  @moduledoc """
  Interface for making requests to the Onvif search service

  https://www.onvif.org/ver10/search.wsdl
  """
  import Onvif.Utils.ApiClient, only: [search_request: 4]
  import SweetXml
  import XmlBuilder

  alias Onvif.Search.{
    FindEvents,
    FindRecordingResult,
    FindRecordings,
    GetRecordingSearchResults,
    RecordingSummary
  }

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

  @doc """
  GetRecordingSearchResults acquires the results from a recording search session previously initiated
  by a `Onvif.Search.find_recordings/2` operation. The response shall not include results already
  returned in previous requests for the same session.

  If MaxResults is specified, the response shall not contain more than MaxResults results.
  The number of results relates to the number of recordings. For viewing individual recorded data
  for a signal track use the FindEvents method.

  GetRecordingSearchResults shall block until:
    * MaxResults results are available for the response if MaxResults is specified.
    * MinResults results are available for the response if MinResults is specified.
    * WaitTime has expired.
    * Search is completed or stopped.
  """
  @spec get_recording_search_results(Onvif.Device.t(), GetRecordingSearchResults.t()) ::
          {:ok, FindRecordingResult.t()} | {:error, any()}
  def get_recording_search_results(device, recording_search_result) do
    body = element(:"s:Body", [GetRecordingSearchResults.encode(recording_search_result)])

    search_request(
      device,
      "GetRecordingSearchResults",
      body,
      &parse_get_recording_search_results/1
    )
  end

  @doc """
  GetRecordingSummary is used to get a summary description of all recorded data.
  """
  @spec get_recording_summary(Onvif.Device.t()) :: {:ok, RecordingSummary.t()} | {:error, any()}
  def get_recording_summary(device) do
    body = element(:"s:Body", [element(:"tse:GetRecordingSummary")])
    search_request(device, "GetRecordingSummary", body, &parse_get_recording_summary/1)
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

  defp parse_get_recording_search_results(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//tse:GetRecordingSearchResultsResponse/tse:ResultList"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tse", "http://www.onvif.org/ver10/search/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> FindRecordingResult.parse()
    |> FindRecordingResult.to_struct()
  end

  defp parse_get_recording_summary(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//tse:GetRecordingSummaryResponse/tse:Summary"e
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("tse", "http://www.onvif.org/ver10/search/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> RecordingSummary.parse()
    |> RecordingSummary.to_struct()
  end
end
