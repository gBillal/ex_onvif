defmodule Onvif.Event.ServiceCapabilities do
  @moduledoc """
  Schema describing the capabilities of the event service
  """

  use TypedEctoSchema

  import Ecto.Changeset
  import SweetXml

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema null: false do
    field :ws_subscription_policy_support, :boolean
    field :ws_pausable_subscription_manager_interface_support, :boolean
    field :max_notification_producers, :integer
    field :max_pull_points, :integer
    field :persistent_notification_storage, :boolean, default: false
    field :event_broker_protocols, {:array, :string}
    field :max_event_brokers, :integer, default: 0
    field :metadata_over_mqtt, :boolean, default: false
  end

  def parse(doc) do
    xmap(doc,
      ws_subscription_policy_support: ~x"./@WSSubscriptionPolicySupport"s,
      ws_pausable_subscription_manager_interface_support:
        ~x"@WSPausableSubscriptionManagerInterfaceSupport"s,
      max_notification_producers: ~x"@MaxNotificationProducers"s,
      max_pull_points: ~x"@MaxPullPoints"s,
      persistent_notification_storage: ~x"@PersistentNotificationStorage"s,
      event_broker_protocols: ~x"@EventBrokerProtocols"S |> transform_by(&String.split(&1, " ")),
      max_event_brokers: ~x"@MaxEventBrokers"s,
      metadata_over_mqtt: ~x"@MetadataOverMQTT"s
    )
  end

  def to_struct(parsed) do
    %__MODULE__{}
    |> changeset(parsed)
    |> apply_action(:validate)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :ws_subscription_policy_support,
      :ws_pausable_subscription_manager_interface_support,
      :max_notification_producers,
      :max_pull_points,
      :persistent_notification_storage,
      :event_broker_protocols,
      :max_event_brokers,
      :metadata_over_mqtt
    ])
  end
end
