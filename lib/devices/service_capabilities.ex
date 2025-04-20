defmodule Onvif.Devices.ServiceCapabilities do
  @moduledoc """
  Schema describing device service capabilities.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import SweetXml

  @type t :: %__MODULE__{}

  @primary_key false
  @derive Jason.Encoder
  embedded_schema do
    embeds_one :network, NetworkCapabilities, primary_key: false do
      @derive Jason.Encoder
      field(:ip_filter, :boolean)
      field(:zero_configration, :boolean, default: false)
      field(:ip_version6, :boolean)
      field(:dyn_dns, :boolean)
      field(:dot11_configuration, :boolean)
      field(:dot1x_configurations, :boolean)
      field(:hostname_from_dhcp, :boolean)
      field(:ntp, :integer)
      field(:dhcp_v6, :boolean)
    end

    embeds_one :security, SecurityCapabilities, primary_key: false do
      @derive Jason.Encoder
      field(:tls10, :boolean)
      field(:tls11, :boolean)
      field(:tls12, :boolean)
      field(:onboard_key_generation, :boolean)
      field(:access_policy_config, :boolean)
      field(:default_access_policy, :boolean)
      field(:dot1x, :boolean)
      field(:remote_user_handling, :boolean)
      field(:x509_token, :boolean)
      field(:saml_token, :boolean)
      field(:kerberos_token, :boolean)
      field(:username_token, :boolean)
      field(:http_digest, :boolean)
      field(:rel_token, :boolean)
      field(:json_web_token, :boolean)
      field(:supported_eap_methods, {:array, :integer})
      field(:max_users, :integer)
      field(:max_username_length, :integer)
      field(:max_password_length, :integer)
      field(:security_policies, {:array, :string})
      field(:max_password_history, :integer)
      field(:hashing_algorithms, {:array, :string})
    end

    embeds_one :system, SystemCapabilities, primary_key: false do
      @derive Jason.Encoder
      field(:discovery_resolve, :boolean)
      field(:discovery_bye, :boolean)
      field(:remote_discovery, :boolean)
      field(:system_backup, :boolean)
      field(:system_logging, :boolean)
      field(:firmware_upgrade, :boolean)
      field(:http_firmware_upgrade, :boolean)
      field(:http_system_backup, :boolean)
      field(:http_system_logging, :boolean)
      field(:http_support_information, :boolean)
      field(:storage_configuration, :boolean)
      field(:max_storage_configurations, :integer)
      field(:geo_location_entries, :integer)
      field(:auto_geo, {:array, :string})
      field(:storage_types_supported, {:array, :string})
      field(:discovery_not_supported, :boolean)
      field(:network_config_not_supported, :boolean)
      field(:user_config_not_supported, :boolean)
      field(:addons, {:array, :string})
      field(:hardware_type, :string)
    end
  end

  def parse(doc) do
    doc
    |> xmap(
      network: [
        ~x"./tds:Network"e,
        ip_filter: ~x"./@IPFilter"s,
        zero_configuration: ~x"./@ZeroConfiguration"s,
        ip_version6: ~x"./@IPVersion6"s,
        dyn_dns: ~x"./@DynDNS"s,
        dot11_configuration: ~x"./@Dot11Configuration"s,
        dot1x_configurations: ~x"./@Dot1XConfigurations"s,
        hostname_from_dhcp: ~x"./@HostnameFromDHCP"s,
        ntp: ~x"./@NTP"s,
        dhcp_v6: ~x"./@DHCPv6"s
      ],
      security: [
        ~x"./tds:Security"e,
        tls10: ~x"./@TLS1.0"s,
        tls11: ~x"./@TLS1.1"s,
        tls12: ~x"./@TLS1.2"s,
        onboard_key_generation: ~x"./@OnboardKeyGeneration"s,
        access_policy_config: ~x"./@AccessPolicyConfig"s,
        default_access_policy: ~x"./@DefaultAccessPolicy"s,
        dot1x: ~x"./@Dot1X"s,
        remote_user_handling: ~x"./@RemoteUserHandling"s,
        x509_token: ~x"./@X.509Token"s,
        saml_token: ~x"./@SAMLToken"s,
        kerberos_token: ~x"./@KerberosToken"s,
        username_token: ~x"./@UsernameToken"s,
        http_digest: ~x"./@HttpDigest"s,
        rel_token: ~x"./@RELToken"s,
        json_web_token: ~x"./@JsonWebToken"s,
        supported_eap_methods: ~x"./@SupportedEAPMethods"s |> transform_by(&String.split/1),
        max_users: ~x"./@MaxUsers"s,
        max_username_length: ~x"./@MaxUserNameLength"s,
        max_password_length: ~x"./@MaxPasswordLength"s,
        security_policies: ~x"./@SecurityPolicies"s |> transform_by(&String.split/1),
        max_password_history: ~x"./@MaxPasswordHistory"s,
        hashing_algorithms: ~x"./@HashingAlgorithms"s |> transform_by(&String.split/1)
      ],
      system: [
        ~x"./tds:System"e,
        discovery_resolve: ~x"./@DiscoveryResolve"s,
        discovery_bye: ~x"./@DiscoveryBye"s,
        remote_discovery: ~x"./@RemoteDiscovery"s,
        system_backup: ~x"./@SystemBackup"s,
        system_logging: ~x"./@SystemLogging"s,
        firmware_upgrade: ~x"./@FirmwareUpgrade"s,
        http_firmware_upgrade: ~x"./@HttpFirmwareUpgrade"s,
        http_system_backup: ~x"./@HttpSystemBackup"s,
        http_system_logging: ~x"./@HttpSystemLogging"s,
        http_support_information: ~x"./@HttpSupportInformation"s,
        storage_configuration: ~x"./@StorageConfiguration"s,
        max_storage_configurations: ~x"./@MaxStorageConfigurations"s,
        geo_location_entries: ~x"./@GeoLocationEntries"s,
        auto_geo: ~x"./@AutoGeo"s |> transform_by(&String.split/1),
        storage_types_supported: ~x"./@StorageTypesSupported"s |> transform_by(&String.split/1),
        discovery_not_supported: ~x"./@DiscoveryNotSupported"s,
        network_config_not_supported: ~x"./@NetworkConfigNotSupported"s,
        user_config_not_supported: ~x"./@UserConfigNotSupported"s,
        addons: ~x"./@Addons"s |> transform_by(&String.split/1),
        hardware_type: ~x"./@HardwareType"s
      ]
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [])
    |> cast_embed(:network, with: &network_changeset/2)
    |> cast_embed(:security, with: &security_changeset/2)
    |> cast_embed(:system, with: &system_changeset/2)
  end

  defp network_changeset(module, attrs) do
    fields = __MODULE__.NetworkCapabilities.__schema__(:fields)
    cast(module, attrs, fields)
  end

  defp security_changeset(module, attrs) do
    fields = __MODULE__.SecurityCapabilities.__schema__(:fields)
    cast(module, attrs, fields)
  end

  defp system_changeset(module, attrs) do
    fields = __MODULE__.SystemCapabilities.__schema__(:fields)
    cast(module, attrs, fields)
  end
end
