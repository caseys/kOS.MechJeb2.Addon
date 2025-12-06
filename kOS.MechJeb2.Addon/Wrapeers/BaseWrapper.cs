using System;
using System.Reflection;
using kOS.MechJeb2.Addon.Core;
using kOS.MechJeb2.Addon.Utils;
using kOS.Safe.Encapsulation;
using kOS.Safe.Encapsulation.Suffixes;
using kOS.Safe.Utilities;
using KSPBuildTools;

namespace kOS.MechJeb2.Addon.Wrapeers
{
    [KOSNomenclature("BaseWrapper")]
    public abstract class BaseWrapper : Structure, IBaseWrapper, ILogContextProvider
    {
        private Func<object, object> _getterMasterMechJeb;
        protected object CoreInstance { get; private set; }

        // Cached reflection info for getting fresh MasterMechJeb
        private static MethodInfo _getMasterMechJebMethod;
        private static bool _reflectionInitialized;

        /// <summary>
        /// Gets MasterMechJeb, automatically refreshing from FlightGlobals.ActiveVessel if the cached instance is stale.
        /// This handles save reloads where the old CoreInstance becomes a destroyed Unity object.
        /// </summary>
        protected object MasterMechJeb
        {
            get
            {
                // First try the cached getter
                var master = _getterMasterMechJeb?.Invoke(CoreInstance);

                // Check if it's valid (not null and not a destroyed Unity object)
                if (master != null)
                {
                    try
                    {
                        // Accessing ToString() on a destroyed Unity object throws
                        if (master.ToString() != "null")
                            return master;
                    }
                    catch
                    {
                        // Fall through to get fresh instance
                    }
                }

                // MasterMechJeb is stale - get a fresh one from the active vessel
                return GetFreshMasterMechJeb();
            }
        }

        /// <summary>
        /// Gets a fresh MasterMechJeb from FlightGlobals.ActiveVessel.
        /// This is the same logic as Addon.TryInitializeMechJebCore.
        /// </summary>
        private static object GetFreshMasterMechJeb()
        {
            if (!_reflectionInitialized)
            {
                var vesselExtensionType = Constants.VesselExtensionName.GetTypeFromCache();
                if (vesselExtensionType != null)
                {
                    _getMasterMechJebMethod = vesselExtensionType.GetMethod("GetMasterMechJeb",
                        BindingFlags.Public | BindingFlags.Static);
                }
                _reflectionInitialized = true;
            }

            if (_getMasterMechJebMethod == null)
                return null;

            var vessel = FlightGlobals.ActiveVessel;
            if (vessel == null)
                return null;

            try
            {
                return _getMasterMechJebMethod.Invoke(null, new object[] { vessel });
            }
            catch
            {
                return null;
            }
        }
        
        public bool Initialized { get; protected set; }

        public virtual void Initialize(object coreInstance, bool force = false)
        {
            if (Initialized && !force) return;
            CoreInstance = coreInstance;
            _getterMasterMechJeb = Reflect.On(CoreInstance).Property("MasterMechJeb").AsGetter<object>();
            BindObject();
            RegisterInitializer(InitializeSuffixes);
            Initialized = true;
        }

        protected void AddSufixInternal(string name, Func<object, double> getter, object o, string description,
            params string[] aliases)
        {
            var suffix = new NoArgsSuffix<ScalarDoubleValue>(() => getter(o), description);

            if (aliases != null && aliases.Length > 0)
            {
                var names = new string[1 + aliases.Length];
                names[0] = name;
                for (int i = 0; i < aliases.Length; i++)
                    names[i + 1] = aliases[i];

                AddSuffix(names, suffix);
            }
            else
            {
                AddSuffix(name, suffix);
            }
        }

        protected void AddSufixInternal(string name, Delegate getter, object o, string description, params string[] aliases)
        {
            ISuffix suffix;

            if (getter is Func<object, double> gd)
                suffix = new NoArgsSuffix<ScalarDoubleValue>(() => gd(o), description);
            else if (getter is Func<object, int> gi)
                suffix = new NoArgsSuffix<ScalarIntValue>(() => gi(o), description);
            else if (getter is Func<object, float> gf)
                suffix = new NoArgsSuffix<ScalarDoubleValue>(() => gf(o),
                    description); // float → double
            else if (getter is Func<object, string> gs)
                suffix = new NoArgsSuffix<StringValue>(() => gs(o), description);
            else
                return;

            if (aliases != null && aliases.Length > 0)
            {
                var names = new string[aliases.Length + 1];
                names[0] = name;
                for (int i = 0; i < aliases.Length; i++)
                    names[i + 1] = aliases[i];

                AddSuffix(names, suffix);
            }
            else
            {
                AddSuffix(name, suffix);
            }
        }

        protected virtual void BindObject()
        {
        }

        protected abstract void InitializeSuffixes();
        public abstract string context();
        
        protected MemberBinder Member(object target, string name)
            => new MemberBinder(target, name);

        protected class MemberBinder
        {
            private readonly object _target;
            private readonly string _name;

            public MemberBinder(object target, string name)
            {
                _target = target;
                _name = name;
            }

            public Func<object, T> GetField<T>()
                => Reflect.On(_target).Field(_name).AsGetter<T>();

            public Action<object, T> SetField<T>()
                => Reflect.On(_target).Field(_name).AsSetter<T>();

            public Func<object, T> GetProp<T>()
                => Reflect.On(_target).Property(_name).AsGetter<T>();

            public Action<object, T> SetProp<T>()
                => Reflect.On(_target).Property(_name).AsSetter<T>();
        }
    }
}