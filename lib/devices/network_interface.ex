defmodule Onvif.Devices.NetworkInterface do
  @moduledoc """
  Device's network interface
  """

  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  alias Onvif.Devices.NetworkInterface.{ConnectionSetting, PrefixedIPAddress}

  @required [:token, :enabled]

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    field(:token, :string)
    field(:enabled, :boolean)

    embeds_one :info, Info, primary_key: false do
      @derive Jason.Encoder

      field(:name, :string)
      field(:hw_address, :string)
      field(:mtu, :integer)
    end

    embeds_one :link, Link, primary_key: false do
      @derive Jason.Encoder

      field(:interface_type, :integer)

      embeds_one(:admin_settings, ConnectionSetting)
      embeds_one(:oper_settings, ConnectionSetting)
    end

    embeds_one :ipv4, IPv4, primary_key: false do
      @derive Jason.Encoder

      field(:enabled, :boolean)

      embeds_one :config, Config, primary_key: false do
        @derive Jason.Encoder

        field(:dhcp, :boolean)

        embeds_one(:manual, PrefixedIPAddress)
        embeds_one(:link_local, PrefixedIPAddress)
        embeds_one(:from_dhcp, PrefixedIPAddress)
      end
    end

    embeds_one :ipv6, IPv6, primary_key: false do
      @derive Jason.Encoder

      field(:enabled, :boolean)

      embeds_one :config, Config, primary_key: false do
        @derive Jason.Encoder

        field(:accept_router_advert, :boolean)

        field(:dhcp, Ecto.Enum,
          values: [auto: "Auto", stateful: "Stateful", stateless: "Stateless", off: "Off"]
        )

        embeds_one(:manual, PrefixedIPAddress)
        embeds_one(:link_local, PrefixedIPAddress)
        embeds_one(:from_dhcp, PrefixedIPAddress)
        embeds_one(:from_ra, PrefixedIPAddress)
      end
    end
  end

  def parse(nil), do: nil
  def parse([]), do: nil

  def parse(doc) do
    xmap(
      doc,
      token: ~x"./@token"s,
      enabled: ~x"./tt:Enabled/text()"s,
      info: ~x"./tt:Info"e |> transform_by(&parse_info/1),
      link: ~x"./tt:Link"e |> transform_by(&parse_link/1),
      ipv4: ~x"./tt:IPv4"e |> transform_by(&parse_ipv4/1),
      ipv6: ~x"./tt:IPv6"e |> transform_by(&parse_ipv6/1)
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  defp parse_info(nil), do: nil
  defp parse_info([]), do: nil

  defp parse_info(doc) do
    xmap(
      doc,
      name: ~x"./tt:Name/text()"s,
      hw_address: ~x"./tt:HwAddress/text()"s,
      mtu: ~x"./tt:MTU/text()"i
    )
  end

  defp parse_link(nil), do: nil
  defp parse_link([]), do: nil

  defp parse_link(doc) do
    xmap(
      doc,
      interface_type: ~x"./tt:InterfaceType/text()"i,
      admin_settings: ~x"./tt:AdminSettings"e |> transform_by(&ConnectionSetting.parse/1),
      oper_settings: ~x"./tt:OperSettings"e |> transform_by(&ConnectionSetting.parse/1)
    )
  end

  defp parse_ipv4(nil), do: nil
  defp parse_ipv4([]), do: nil

  defp parse_ipv4(doc) do
    xmap(
      doc,
      enabled: ~x"./tt:Enabled/text()"s,
      config: ~x"./tt:Config"e |> transform_by(&parse_ipv4_config/1)
    )
  end

  defp parse_ipv6(nil), do: nil
  defp parse_ipv6([]), do: nil

  defp parse_ipv6(doc) do
    xmap(
      doc,
      enabled: ~x"./tt:Enabled/text()"s,
      config: ~x"./tt:Config"e |> transform_by(&parse_ipv6_config/1)
    )
  end

  defp parse_ipv4_config(nil), do: nil
  defp parse_ipv4_config([]), do: nil

  defp parse_ipv4_config(doc) do
    xmap(
      doc,
      dhcp: ~x"./tt:DHCP/text()"s,
      manual: ~x"./tt:Manual"e |> transform_by(&PrefixedIPAddress.parse/1),
      link_local: ~x"./tt:LinkLocal"e |> transform_by(&PrefixedIPAddress.parse/1),
      from_dhcp: ~x"./tt:FromDHCP"e |> transform_by(&PrefixedIPAddress.parse/1)
    )
  end

  defp parse_ipv6_config(nil), do: nil
  defp parse_ipv6_config([]), do: nil

  defp parse_ipv6_config(doc) do
    xmap(
      doc,
      accept_router_advert: ~x"./tt:AcceptRouterAdvert/text()"so,
      dhcp: ~x"./tt:DHCP/text()"s,
      manual: ~x"./tt:Manual"e |> transform_by(&PrefixedIPAddress.parse/1),
      link_local: ~x"./tt:LinkLocal"e |> transform_by(&PrefixedIPAddress.parse/1),
      from_dhcp: ~x"./tt:FromDHCP"e |> transform_by(&PrefixedIPAddress.parse/1),
      from_ra: ~x"./tt:FromRA"e |> transform_by(&PrefixedIPAddress.parse/1)
    )
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, @required)
    |> cast_embed(:info, with: &info_changeset/2)
    |> cast_embed(:link, with: &link_changeset/2)
    |> cast_embed(:ipv4, with: &ipv4_changeset/2)
    |> cast_embed(:ipv6, with: &ipv6_changeset/2)
  end

  defp info_changeset(module, attrs) do
    cast(module, attrs, [:name, :hw_address, :mtu])
  end

  defp link_changeset(module, attrs) do
    module
    |> cast(attrs, [:interface_type])
    |> cast_embed(:admin_settings)
    |> cast_embed(:oper_settings)
  end

  defp ipv4_changeset(module, attrs) do
    module
    |> cast(attrs, [:enabled])
    |> cast_embed(:config, with: &ipv4_config_changeset/2)
  end

  defp ipv4_config_changeset(module, attrs) do
    module
    |> cast(attrs, [:dhcp])
    |> cast_embed(:manual)
    |> cast_embed(:link_local)
    |> cast_embed(:from_dhcp)
  end

  defp ipv6_changeset(module, attrs) do
    module
    |> cast(attrs, [:enabled])
    |> cast_embed(:config, with: &ipv6_config_changeset/2)
  end

  defp ipv6_config_changeset(module, attrs) do
    module
    |> cast(attrs, [:accept_router_advert, :dhcp])
    |> cast_embed(:manual)
    |> cast_embed(:link_local)
    |> cast_embed(:from_dhcp)
    |> cast_embed(:from_ra)
  end
end
