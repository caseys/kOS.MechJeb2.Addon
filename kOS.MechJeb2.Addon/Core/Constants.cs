namespace kOS.MechJeb2.Addon.Core
{
    public static class Constants
    {
        /// <summary>
        /// Property name for accessing the value of MechJeb's Editable types.
        /// Both EditableDouble and EditableInt use a property named "Val".
        /// </summary>
        public static readonly string EditableValuePropertyName = "Val";
        public static readonly string MechjebAssemblyName = "MechJeb2";
        public static readonly string MechjebCoreName = "MuMech.MechJebCore";
        public static readonly string VesselExtensionName = "MuMech.VesselExtensions";
        
        public static readonly string MechjebCoreModuleName = "MechJebCore";
        public static readonly string GetComputerModuleMethod = "GetComputerModule";
    }
}