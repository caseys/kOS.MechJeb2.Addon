using kOS.MechJeb2.Addon.Wrapeers;
using kOS.Safe.Encapsulation;

namespace kOS.MechJeb2.Addon
{
    /// <summary>
    /// Static controller that manages the MechJeb wrapper instance.
    /// Subscribes to GameEvents to detect save reloads and clear stale references.
    /// </summary>
    public static class MechJebController
    {
        private static MechJebCoreWrapper _instance;
        private static bool _eventsSubscribed;

        /// <summary>
        /// Set to true when GameEvents fire, signaling that cached references are stale.
        /// Addon should check this and force reinitialization if true.
        /// </summary>
        public static bool NeedsReinitialization { get; private set; }

        public static MechJebCoreWrapper Instance
        {
            get
            {
                EnsureEventsSubscribed();
                return _instance ??= new MechJebCoreWrapper();
            }
        }

        public static BooleanValue IsAvailable => Instance is { Initialized: true };

        /// <summary>
        /// Subscribe to KSP GameEvents to detect when saves are reloaded.
        /// This ensures we clear stale MechJeb references when the flight scene changes.
        /// </summary>
        private static void EnsureEventsSubscribed()
        {
            if (_eventsSubscribed) return;

            // Guard against GameEvents not being initialized yet
            if (GameEvents.onFlightReady == null ||
                GameEvents.onVesselChange == null ||
                GameEvents.onGameSceneLoadRequested == null)
            {
                return;
            }

            try
            {
                // onFlightReady fires when entering flight scene (including save reloads)
                GameEvents.onFlightReady.Add(OnFlightReady);

                // onVesselChange fires when switching between vessels
                GameEvents.onVesselChange.Add(OnVesselChange);

                // onGameSceneLoadRequested fires before loading any scene (cleanup opportunity)
                GameEvents.onGameSceneLoadRequested.Add(OnGameSceneLoadRequested);

                _eventsSubscribed = true;
            }
            catch
            {
                // GameEvents exist but aren't ready to accept subscribers yet - will retry next access
            }
        }

        private static void OnFlightReady()
        {
            _instance = null;
            NeedsReinitialization = true;
        }

        private static void OnVesselChange(Vessel vessel)
        {
            _instance = null;
            NeedsReinitialization = true;
        }

        private static void OnGameSceneLoadRequested(GameScenes scene)
        {
            _instance = null;
            NeedsReinitialization = true;
        }

        /// <summary>
        /// Called by Addon after successful reinitialization.
        /// </summary>
        public static void ClearReinitializationFlag()
        {
            NeedsReinitialization = false;
        }
    }
}