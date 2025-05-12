alsa_monitor.enabled = true

alsa_monitor.properties = {
  ["alsa.reserve"] = false,
  ["alsa.midi"] = false,
  ["alsa.midi.monitoring"] = true,
  ["vm.node.defaults"] = {
    ["api.alsa.period-size"] = 256,
    ["api.alsa.headroom"] = 8192,
  },
}

alsa_monitor.rules = {
  {
    matches = {
      {
        { "device.name", "matches", "alsa_card.*" },
      },
    },
    apply_properties = {
      ["api.alsa.use-acp"] = false,
      ["api.alsa.use-ucm"] = false,
      ["api.alsa.soft-mixer"] = true,
      ["api.acp.auto-profile"] = false,
      ["api.acp.auto-port"] = false,
    },
  },
  {
    matches = {
      {
        { "node.name", "matches", "alsa_input.*" },
      },
      {
        { "node.name", "matches", "alsa_output.*" },
      },
    },
    apply_properties = {
      ["api.alsa.card.0.device"] = "audiocodec",
      ["api.alsa.soft-mixer"] = true,
      ["alsa.mixer.control"] = "Master",
      ["alsa.mixer.device"] = "audiocodec",
      ["alsa.mixer.invert-volume"] = true,
    },
  },
}
