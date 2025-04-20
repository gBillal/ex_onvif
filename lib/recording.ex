defmodule Onvif.Recording2 do
  @moduledoc """
  Interface for making requests to the Onvif recording service

  http://www.onvif.org/onvif/ver10/recording.wsdl
  """

  import Onvif.ApiUtils, only: [recording_request: 4]
  import SweetXml
  import XmlBuilder

  alias Onvif.Recording.Schemas.{Recording, RecordingJob}

  @doc """
  GetRecordings shall return a description of all the recordings in the device.

  This description shall include a list of all the tracks for each recording.
  """
  @spec get_recordings(Onvif.Device.t()) :: {:ok, [Recording.t()]} | {:error, any()}
  def get_recordings(device) do
    body = element(:"s:Body", [element(:"trc:GetRecordings")])
    recording_request(device, "GetRecordings", body, &parse_recordings_response/1)
  end

  @doc """
  GetRecordingJobs shall return a list of all the recording jobs in the device.
  """
  @spec get_recording_jobs(Onvif.Device.t()) :: {:ok, [RecordingJob.t()]} | {:error, any()}
  def get_recording_jobs(device) do
    body = element(:"s:Body", [element(:"trc:GetRecordingJobs")])
    recording_request(device, "GetRecordingJobs", body, &parse_recording_jobs_response/1)
  end

  defp parse_recordings_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trc:GetRecordingsResponse/trc:RecordingItem"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trc", "http://www.onvif.org/ver10/recording/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&Recording.parse/1)
    |> Enum.reduce_while([], fn raw_recording, acc ->
      case Recording.to_struct(raw_recording) do
        {:ok, recording} -> {:cont, [recording | acc]}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      recordings -> {:ok, Enum.reverse(recordings)}
    end
  end

  defp parse_recording_jobs_response(xml_response_body) do
    xml_response_body
    |> parse(namespace_conformant: true, quiet: true)
    |> xpath(
      ~x"//s:Envelope/s:Body/trc:GetRecordingJobsResponse/trc:JobItem"el
      |> add_namespace("s", "http://www.w3.org/2003/05/soap-envelope")
      |> add_namespace("trc", "http://www.onvif.org/ver10/recording/wsdl")
      |> add_namespace("tt", "http://www.onvif.org/ver10/schema")
    )
    |> Enum.map(&RecordingJob.parse/1)
    |> Enum.reduce_while([], fn raw_job, acc ->
      case RecordingJob.to_struct(raw_job) do
        {:ok, job} -> {:cont, [job | acc]}
        error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _reason} = err -> err
      jobs -> {:ok, Enum.reverse(jobs)}
    end
  end
end
