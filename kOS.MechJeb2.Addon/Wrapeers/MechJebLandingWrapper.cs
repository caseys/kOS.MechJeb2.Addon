using System;
using System.Collections.Generic;
using System.Reflection;
using kOS.MechJeb2.Addon.Core;
using kOS.MechJeb2.Addon.Utils;
using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;
using kOS.Safe.Exceptions;
using kOS.Safe.Utilities;
using UnityEngine;

namespace kOS.MechJeb2.Addon.Wrapeers
{
    /// <summary>
    /// kOS wrapper for MechJeb's Landing Autopilot module.
    /// Provides suffixes for controlling automated landing sequences including
    /// targeted landing, untargeted landing, and landing configuration.
    /// </summary>
    /// <remarks>
    /// Uses fresh module instance pattern - LandingAutopilot property fetches
    /// the current module on each access to avoid stale references after save reload.
    /// </remarks>
    [KOSNomenclature("LandingWrapper")]
    public class MechJebLandingWrapper : BaseWrapper
    {
        // Module getter - uses GetField since Landing is a field, not property
        private Func<object, object> _landingAutopilotGetter;

        // Gets fresh landing module from current MasterMechJeb
        private object LandingAutopilot => _landingAutopilotGetter(MasterMechJeb);

        // Users pool for proper autopilot engagement
        private Func<object, object> _usersGetter;
        private Action<object, object> _usersAdd;
        private Action<object, object> _usersRemove;
        private Func<object, int> _usersCount;
        private readonly object _userIdentity = new object();

        // Log throttling - only log each error type once until success
        private readonly HashSet<string> _loggedErrors = new HashSet<string>();

        // Control methods - bound to type, invoked on fresh instance
        private MethodInfo _landAtPositionTargetMethod;
        private MethodInfo _landUntargetedMethod;
        private MethodInfo _stopLandingMethod;

        // Status - bound to type for fresh access
        private Func<object, bool> _getEnabled;
        private Func<object, string> _getStatus;
        private Func<object, bool> _getLandAtTarget;

        // Configuration - these work with fresh module via LandingAutopilot property
        private Func<object, double> _getTouchdownSpeed;
        private Action<object, double> _setTouchdownSpeed;
        private Func<object, bool> _getDeployGears;
        private Action<object, bool> _setDeployGears;
        private Func<object, bool> _getDeployChutes;
        private Action<object, bool> _setDeployChutes;
        private Func<object, bool> _getRCSAdjustment;
        private Action<object, bool> _setRCSAdjustment;
        private Func<object, int> _getLimitGearsStage;
        private Action<object, int> _setLimitGearsStage;
        private Func<object, int> _getLimitChutesStage;
        private Action<object, int> _setLimitChutesStage;

        // Info methods - MethodInfo to invoke on fresh instance
        private MethodInfo _maxAllowedSpeedMethod;
        private MethodInfo _decelerationEndAltitudeMethod;
        private MethodInfo _useAtmosphereToBrakeMethod;
        private MethodInfo _parachutesDeployableMethod;

        // Prediction accessors
        private Func<object, object> _predictionGetter;
        private Func<object, bool> _getPredictionReady;

        protected override void BindObject()
        {
            var masterMechJeb = MasterMechJeb;

            // Get the landing autopilot module - Landing is a FIELD, not property
            _landingAutopilotGetter = Member(masterMechJeb, "Landing").GetField<object>();
            var landing = LandingAutopilot;

            // Get the landing autopilot type for binding methods
            var landingType = landing.GetType();

            // Status properties - bound to type for fresh access
            _getEnabled = Reflect.OnType(landingType).Property("Enabled").AsGetter<bool>();
            _getStatus = Reflect.OnType(landingType).Property("Status").AsGetter<string>();
            _getLandAtTarget = Reflect.OnType(landingType).Field("LandAtTarget").AsGetter<bool>();

            // Bind to Users pool for proper engagement - bind to type
            var usersField = Reflect.OnType(landingType).Field("Users");
            _usersGetter = usersField.AsGetter<object>();
            var users = _usersGetter(landing);
            var usersType = users.GetType();
            _usersAdd = Reflect.OnType(usersType).Method("Add").WithArgs(typeof(object)).AsAction();
            _usersRemove = Reflect.OnType(usersType).Method("Remove").WithArgs(typeof(object)).AsAction();
            _usersCount = Reflect.OnType(usersType).Property("Count").AsGetter<int>();

            // Control methods - cache MethodInfo for invoking on fresh instance
            _landAtPositionTargetMethod = landingType.GetMethod("LandAtPositionTarget",
                BindingFlags.Public | BindingFlags.Instance);
            _landUntargetedMethod = landingType.GetMethod("LandUntargeted",
                BindingFlags.Public | BindingFlags.Instance);
            _stopLandingMethod = landingType.GetMethod("StopLanding",
                BindingFlags.Public | BindingFlags.Instance);

            // Configuration - EditableDouble/EditableInt fields (bind to type)
            (_getTouchdownSpeed, _setTouchdownSpeed) = BindEditableToType<double>(landingType, "TouchdownSpeed");
            (_getLimitGearsStage, _setLimitGearsStage) = BindEditableToType<int>(landingType, "LimitGearsStage");
            (_getLimitChutesStage, _setLimitChutesStage) = BindEditableToType<int>(landingType, "LimitChutesStage");

            // Configuration - bool fields (bind to type)
            _getDeployGears = Reflect.OnType(landingType).Field("DeployGears").AsGetter<bool>();
            _setDeployGears = Reflect.OnType(landingType).Field("DeployGears").AsSetter<bool>();
            _getDeployChutes = Reflect.OnType(landingType).Field("DeployChutes").AsGetter<bool>();
            _setDeployChutes = Reflect.OnType(landingType).Field("DeployChutes").AsSetter<bool>();
            _getRCSAdjustment = Reflect.OnType(landingType).Field("RCSAdjustment").AsGetter<bool>();
            _setRCSAdjustment = Reflect.OnType(landingType).Field("RCSAdjustment").AsSetter<bool>();

            // Info methods - cache MethodInfo for invoking on fresh instance
            _maxAllowedSpeedMethod = landingType.GetMethod("MaxAllowedSpeed",
                BindingFlags.Public | BindingFlags.Instance);
            _decelerationEndAltitudeMethod = landingType.GetMethod("DecelerationEndAltitude",
                BindingFlags.Public | BindingFlags.Instance);
            _useAtmosphereToBrakeMethod = landingType.GetMethod("UseAtmosphereToBrake",
                BindingFlags.Public | BindingFlags.Instance);
            _parachutesDeployableMethod = landingType.GetMethod("ParachutesDeployable",
                BindingFlags.Public | BindingFlags.Instance);

            // Prediction - bind to type for fresh access
            _getPredictionReady = Reflect.OnType(landingType).Property("PredictionReady").AsGetter<bool>();
            _predictionGetter = Reflect.OnType(landingType).Property("Prediction").AsGetter<object>();
        }

        protected override void InitializeSuffixes()
        {
            // Control
            AddSuffix("ENABLED",
                new SetSuffix<BooleanValue>(() => Enabled, value => Enabled = value,
                    "Is landing autopilot enabled?"));

            AddSuffix("STATUS",
                new NoArgsSuffix<StringValue>(() => GetStatus(),
                    "Current autopilot step status"));

            AddSuffix("LANDATTARGET",
                new NoArgsSuffix<BooleanValue>(() => _getLandAtTarget(LandingAutopilot),
                    "Is landing at a specific target?"));

            AddSuffix("LANDATPOSITIONTARGET",
                new NoArgsSuffix<BooleanValue>(LandAtPositionTarget,
                    "Start landing at the current target position"));

            AddSuffix("LANDUNTARGETED",
                new NoArgsSuffix<BooleanValue>(LandUntargeted,
                    "Start untargeted landing"));

            AddSuffix("LANDSOMEWHERE",
                new NoArgsSuffix<BooleanValue>(LandUntargeted,
                    "Start untargeted landing (alias for LANDUNTARGETED)"));

            AddSuffix("STOPLANDING",
                new NoArgsSuffix<BooleanValue>(StopLanding,
                    "Abort landing sequence"));

            // Configuration
            AddSuffix(new[] { "TOUCHDOWNSPEED", "TDSPEED" },
                new SetSuffix<ScalarDoubleValue>(
                    () => _getTouchdownSpeed(LandingAutopilot),
                    value => _setTouchdownSpeed(LandingAutopilot, value),
                    "Target touchdown speed (m/s)"));

            AddSuffix(new[] { "DEPLOYGEARS", "GEARS" },
                new SetSuffix<BooleanValue>(
                    () => _getDeployGears(LandingAutopilot),
                    value => _setDeployGears(LandingAutopilot, value),
                    "Auto-deploy landing gear"));

            AddSuffix(new[] { "DEPLOYCHUTES", "CHUTES" },
                new SetSuffix<BooleanValue>(
                    () => _getDeployChutes(LandingAutopilot),
                    value => _setDeployChutes(LandingAutopilot, value),
                    "Auto-deploy parachutes"));

            AddSuffix(new[] { "RCSADJUSTMENT", "RCS" },
                new SetSuffix<BooleanValue>(
                    () => _getRCSAdjustment(LandingAutopilot),
                    value => _setRCSAdjustment(LandingAutopilot, value),
                    "Use RCS for fine positioning"));

            AddSuffix(new[] { "LIMITGEARSSTAGE", "GEARSTAGE" },
                new SetSuffix<ScalarIntValue>(
                    () => _getLimitGearsStage(LandingAutopilot),
                    value => _setLimitGearsStage(LandingAutopilot, value),
                    "Maximum stage to deploy gears from"));

            AddSuffix(new[] { "LIMITCHUTESSTAGE", "CHUTESTAGE" },
                new SetSuffix<ScalarIntValue>(
                    () => _getLimitChutesStage(LandingAutopilot),
                    value => _setLimitChutesStage(LandingAutopilot, value),
                    "Maximum stage to deploy chutes from"));

            // Prediction
            AddSuffix("PREDICTIONREADY",
                new NoArgsSuffix<BooleanValue>(() => _getPredictionReady(LandingAutopilot),
                    "Is landing prediction valid?"));

            AddSuffix(new[] { "PREDICTEDLAT", "PREDLAT" },
                new NoArgsSuffix<ScalarDoubleValue>(GetPredictedLatitude,
                    "Predicted landing latitude"));

            AddSuffix(new[] { "PREDICTEDLNG", "PREDLNG" },
                new NoArgsSuffix<ScalarDoubleValue>(GetPredictedLongitude,
                    "Predicted landing longitude"));

            AddSuffix(new[] { "PREDICTEDALT", "PREDALT" },
                new NoArgsSuffix<ScalarDoubleValue>(GetPredictedAltitude,
                    "Predicted landing altitude (ASL)"));

            AddSuffix(new[] { "PREDICTEDUT", "PREDUT" },
                new NoArgsSuffix<ScalarDoubleValue>(GetPredictedUT,
                    "Predicted landing time (UT)"));

            AddSuffix(new[] { "PREDICTEDOUTCOME", "PREDOUTCOME" },
                new NoArgsSuffix<StringValue>(GetPredictedOutcome,
                    "Predicted outcome (LANDED, AEROBRAKED, NO_REENTRY, etc.)"));

            // Info
            AddSuffix("MAXALLOWEDSPEED",
                new NoArgsSuffix<ScalarDoubleValue>(() => GetMaxAllowedSpeed(),
                    "Safe descent speed at current altitude"));

            AddSuffix(new[] { "DECELERATIONENDALT", "DECELALT" },
                new NoArgsSuffix<ScalarDoubleValue>(() => GetDecelerationEndAltitude(),
                    "Altitude where deceleration completes"));

            AddSuffix(new[] { "USEATMOSPHERETOBRAKE", "ATMBRAKE" },
                new NoArgsSuffix<BooleanValue>(() => GetUseAtmosphereToBrake(),
                    "Is atmosphere assisting braking?"));

            AddSuffix(new[] { "PARACHUTESDEPLOYABLE", "CHUTESREADY" },
                new NoArgsSuffix<BooleanValue>(() => GetParachutesDeployable(),
                    "Can parachutes be deployed now?"));
        }

        public override string context() => nameof(MechJebLandingWrapper);

        public BooleanValue Enabled
        {
            get =>
                Initialized
                    ? new BooleanValue(_getEnabled(LandingAutopilot))
                    : throw new KOSException("Cannot get Enabled property of not initialized MechJebLandingWrapper");
            set
            {
                if (!Initialized) return;

                var landing = LandingAutopilot;
                var users = _usersGetter(landing);

                // Use Users.Add/Remove for proper engagement
                if (value)
                    _usersAdd(users, _userIdentity);
                else
                    _usersRemove(users, _userIdentity);
            }
        }

        private StringValue GetStatus()
        {
            if (!Initialized) return "Not initialized";
            return _getStatus(LandingAutopilot) ?? "Off";
        }

        private BooleanValue LandAtPositionTarget()
        {
            if (!Initialized) return false;
            try
            {
                var landing = LandingAutopilot;
                _landAtPositionTargetMethod.Invoke(landing, new object[] { _userIdentity });
                _loggedErrors.Remove("LandAtPositionTarget");  // Reset on success
                return true;
            }
            catch (Exception ex)
            {
                if (_loggedErrors.Add("LandAtPositionTarget"))
                {
                    UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] LandAtPositionTarget failed: {ex}");
                }
                return false;
            }
        }

        private BooleanValue LandUntargeted()
        {
            if (!Initialized) return false;
            try
            {
                var landing = LandingAutopilot;
                _landUntargetedMethod.Invoke(landing, new object[] { _userIdentity });
                _loggedErrors.Remove("LandUntargeted");  // Reset on success
                return true;
            }
            catch (Exception ex)
            {
                if (_loggedErrors.Add("LandUntargeted"))
                {
                    UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] LandUntargeted failed: {ex}");
                }
                return false;
            }
        }

        private BooleanValue StopLanding()
        {
            if (!Initialized) return false;
            try
            {
                var landing = LandingAutopilot;
                _stopLandingMethod.Invoke(landing, null);
                _loggedErrors.Remove("StopLanding");  // Reset on success
                return true;
            }
            catch (Exception ex)
            {
                if (_loggedErrors.Add("StopLanding"))
                {
                    UnityEngine.Debug.Log($"[kOS.MechJeb2.Addon] StopLanding failed: {ex}");
                }
                return false;
            }
        }

        // Prediction accessors - return 0/default when prediction not ready or reflection fails
        // Wrapped in try/catch for dynamic data that may not exist during startup
        private ScalarDoubleValue GetPredictedLatitude()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                if (!_getPredictionReady(landing)) return 0;

                var result = _predictionGetter(landing);
                if (result == null) return 0;

                var endPosition = Reflect.On(result).Property("EndPosition").AsGetter<object>()(result);
                if (endPosition == null) return 0;

                return Reflect.On(endPosition).Property("Latitude").AsGetter<double>()(endPosition);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private ScalarDoubleValue GetPredictedLongitude()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                if (!_getPredictionReady(landing)) return 0;

                var result = _predictionGetter(landing);
                if (result == null) return 0;

                var endPosition = Reflect.On(result).Property("EndPosition").AsGetter<object>()(result);
                if (endPosition == null) return 0;

                return Reflect.On(endPosition).Property("Longitude").AsGetter<double>()(endPosition);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private ScalarDoubleValue GetPredictedAltitude()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                if (!_getPredictionReady(landing)) return 0;

                var result = _predictionGetter(landing);
                if (result == null) return 0;

                return Reflect.On(result).Field("EndASL").AsGetter<double>()(result);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private ScalarDoubleValue GetPredictedUT()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                if (!_getPredictionReady(landing)) return 0;

                var result = _predictionGetter(landing);
                if (result == null) return 0;

                return Reflect.On(result).Field("EndUT").AsGetter<double>()(result);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private StringValue GetPredictedOutcome()
        {
            if (!Initialized) return "UNKNOWN";
            try
            {
                var landing = LandingAutopilot;
                var result = _predictionGetter(landing);
                if (result == null) return "NO_PREDICTION";

                var outcome = Reflect.On(result).Field("Outcome").AsGetter<object>()(result);
                return outcome?.ToString() ?? "UNKNOWN";
            }
            catch
            {
                return "UNKNOWN";  // Silent fallback - expected during startup
            }
        }

        // Info methods - invoke on fresh landing module
        // Wrapped in try/catch for dynamic data that may not exist during startup
        private ScalarDoubleValue GetMaxAllowedSpeed()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                return (double)_maxAllowedSpeedMethod.Invoke(landing, null);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private ScalarDoubleValue GetDecelerationEndAltitude()
        {
            if (!Initialized) return 0;
            try
            {
                var landing = LandingAutopilot;
                return (double)_decelerationEndAltitudeMethod.Invoke(landing, null);
            }
            catch
            {
                return 0;  // Silent fallback - expected during startup
            }
        }

        private BooleanValue GetUseAtmosphereToBrake()
        {
            if (!Initialized) return false;
            try
            {
                var landing = LandingAutopilot;
                return (bool)_useAtmosphereToBrakeMethod.Invoke(landing, null);
            }
            catch
            {
                return false;  // Silent fallback - expected during startup
            }
        }

        private BooleanValue GetParachutesDeployable()
        {
            if (!Initialized) return false;
            try
            {
                var landing = LandingAutopilot;
                return (bool)_parachutesDeployableMethod.Invoke(landing, null);
            }
            catch
            {
                return false;  // Silent fallback - expected during startup
            }
        }

        // Helper to bind EditableDouble/EditableInt fields to type (not instance)
        private (Func<object, T> get, Action<object, T> set) BindEditableToType<T>(Type landingType, string fieldName)
        {
            var fieldInfo = landingType.GetField(fieldName,
                BindingFlags.Public | BindingFlags.Instance);

            // Get the EditableDouble/EditableInt type
            var editableType = fieldInfo.FieldType;
            var valProp = editableType.GetProperty(Constants.EditableValuePropertyName,
                BindingFlags.Public | BindingFlags.Instance);

            Func<object, T> getter = (landing) =>
            {
                var editable = fieldInfo.GetValue(landing);
                return (T)valProp.GetValue(editable);
            };

            Action<object, T> setter = (landing, value) =>
            {
                var editable = fieldInfo.GetValue(landing);
                valProp.SetValue(editable, value);
            };

            return (getter, setter);
        }
    }
}
