defmodule Onvif.Devices.SystemDateAndTime do
  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml
  import XmlBuilder

  @required [:date_time_type, :daylight_savings]
  @optional []

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:date_time_type, Ecto.Enum, values: [manual: "Manual", ntp: "NTP"])
    field(:daylight_savings, :boolean, default: true)
    field(:datetime, :utc_datetime)
    field(:current_diff, :integer)

    embeds_one :time_zone, TimeZone, primary_key: false, on_replace: :update do
      @derive Jason.Encoder
      field(:tz, :string)
    end

    embeds_one :utc_date_time, UTCDateTime, primary_key: false, on_replace: :update do
      @derive Jason.Encoder

      embeds_one :time, Time, primary_key: false, on_replace: :update do
        @derive Jason.Encoder
        field(:hour, :integer)
        field(:minute, :integer)
        field(:second, :integer)
      end

      embeds_one :date, Date, primary_key: false, on_replace: :update do
        @derive Jason.Encoder
        field(:year, :integer)
        field(:month, :integer)
        field(:day, :integer)
      end
    end

    embeds_one :local_date_time, LocalDateTime, primary_key: false, on_replace: :update do
      @derive Jason.Encoder

      embeds_one :time, Time, primary_key: false, on_replace: :update do
        @derive Jason.Encoder
        field(:hour, :integer)
        field(:minute, :integer)
        field(:second, :integer)
      end

      embeds_one :date, Date, primary_key: false, on_replace: :update do
        @derive Jason.Encoder
        field(:year, :integer)
        field(:month, :integer)
        field(:day, :integer)
      end
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      date_time_type: ~x"./tt:DateTimeType/text()"so,
      daylight_savings: ~x"./tt:DaylightSavings/text()"so,
      time_zone: ~x"./tt:TimeZone"eo |> transform_by(&parse_time_zone/1),
      utc_date_time: ~x"./tt:UTCDateTime"eo |> transform_by(&parse_date_time/1),
      local_date_time: ~x"./tt:LocalDateTime"eo |> transform_by(&parse_date_time/1)
    )
  end

  def encode(%__MODULE__{} = datetime) do
    element(:"tds:SetSystemDateAndTime", [
      element(
        :"tds:DateTimeType",
        Keyword.fetch!(
          Ecto.Enum.mappings(datetime.__struct__, :date_time_type),
          datetime.date_time_type
        )
      ),
      element(:"tds:DaylightSavings", datetime.daylight_savings),
      element(
        :"tds:TimeZone",
        [
          element(:"tt:TZ", datetime.time_zone.tz)
        ]
      ),
      List.flatten([utc_date_time_element(datetime.utc_date_time)])
    ])
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> cast_embed(:time_zone, with: &time_zone_changeset/2)
    |> cast_embed(:utc_date_time, with: &date_time_changeset/2)
    |> cast_embed(:local_date_time, with: &date_time_changeset/2)
    |> put_datetime
    |> put_current_diff
  end

  defp parse_time_zone([]), do: nil
  defp parse_time_zone(nil), do: nil

  defp parse_time_zone(doc) do
    xmap(
      doc,
      tz: ~x"./tt:TZ/text()"s
    )
  end

  defp parse_date_time([]), do: nil
  defp parse_date_time(nil), do: nil

  defp parse_date_time(doc) do
    xmap(
      doc,
      time: ~x"./tt:Time"eo |> transform_by(&parse_time/1),
      date: ~x"./tt:Date"eo |> transform_by(&parse_date/1)
    )
  end

  defp parse_time([]), do: nil
  defp parse_time(nil), do: nil

  defp parse_time(doc) do
    xmap(
      doc,
      hour: ~x"./tt:Hour/text()"i,
      minute: ~x"./tt:Minute/text()"i,
      second: ~x"./tt:Second/text()"i
    )
  end

  defp parse_date([]), do: nil
  defp parse_date(nil), do: nil

  defp parse_date(doc) do
    xmap(
      doc,
      year: ~x"./tt:Year/text()"i,
      month: ~x"./tt:Month/text()"i,
      day: ~x"./tt:Day/text()"i
    )
  end

  defp put_datetime(changeset) do
    case get_field(changeset, :utc_date_time) do
      nil ->
        changeset

      utc_date_time ->
        {:ok, date} =
          Date.new(utc_date_time.date.year, utc_date_time.date.month, utc_date_time.date.day)

        {:ok, time} =
          Time.new(utc_date_time.time.hour, utc_date_time.time.minute, utc_date_time.time.second)

        {:ok, datetime} = DateTime.new(date, time)
        put_change(changeset, :datetime, datetime)
    end
  end

  defp put_current_diff(changeset) do
    case get_field(changeset, :datetime) do
      nil ->
        changeset

      datetime ->
        current = DateTime.utc_now()
        diff = DateTime.diff(datetime, current)
        put_change(changeset, :current_diff, diff)
    end
  end

  defp time_zone_changeset(module, attrs) do
    cast(module, attrs, [:tz])
  end

  defp date_time_changeset(module, attrs) do
    cast(module, attrs, [])
    |> cast_embed(:date, with: &date_changeset/2)
    |> cast_embed(:time, with: &time_changeset/2)
  end

  defp date_changeset(module, attrs) do
    cast(module, attrs, [:year, :month, :day])
  end

  defp time_changeset(module, attrs) do
    cast(module, attrs, [:hour, :minute, :second])
  end

  defp utc_date_time_element(nil), do: []

  defp utc_date_time_element(utc_date_time) do
    element(
      :"tds:UTCDateTime",
      [
        element(:"tt:Time", [
          element(:"tt:Hour", utc_date_time.time.hour),
          element(:"tt:Minute", utc_date_time.time.minute),
          element(:"tt:Second", utc_date_time.time.second)
        ]),
        element(:"tt:Date", [
          element(:"tt:Year", utc_date_time.date.year),
          element(:"tt:Month", utc_date_time.date.month),
          element(:"tt:Day", utc_date_time.date.day)
        ])
      ]
    )
  end
end
