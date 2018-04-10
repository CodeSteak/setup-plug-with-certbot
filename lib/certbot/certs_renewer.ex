defmodule Certbot.CertsRenewer do
  use GenServer

  def child_spec(certbot_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [{:certbot_args, certbot_args}]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link({:certbot_args, certbot_args}) do
    # ms
    second = 1000
    minute = 60 * second
    hour = 60 * minute

    time = 5 * hour

    renew_cmd = ["renew" | certbot_args]

    GenServer.start_link(__MODULE__, {time, renew_cmd}, name: __MODULE__)
  end

  def init(args = {time, _renew_cmd}) do
    me = self()
    spawn_link(fn -> watchdog(me) end)

    :timer.send_interval(time, self(), :renew_cert)

    :timer.send_after(99_000, self(), :renew_cert)

    {:ok, args}
  end

  def handle_info({:ping, from}, state) do
    send(from, :pong)

    {:noreply, state}
  end

  def handle_info(:renew_cert, state = {_time, renew_cmd}) do
    IO.puts("Check for renewal of certificates!")

    {a, b} = System.cmd("certbot", renew_cmd)

    IO.puts(a)
    IO.puts("Exit Code #{b}")

    :ssl.clear_pem_cache()

    {:noreply, state}
  end

  defp watchdog(pid) do
    :timer.sleep(11_000)
    send(pid, {:ping, self()})

    receive do
      :pong ->
        watchdog(pid)
    after
      60_000 ->
        throw("CertsRenewer did not respond for 1 Minute!")
    end
  end
end
