//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Lazada.Models
{
    using System;
    using System.Collections.Generic;
    
    public partial class MSmerge_contents
    {
        public int tablenick { get; set; }
        public System.Guid rowguid { get; set; }
        public long generation { get; set; }
        public Nullable<long> partchangegen { get; set; }
        public byte[] lineage { get; set; }
        public byte[] colv1 { get; set; }
        public Nullable<System.Guid> marker { get; set; }
        public Nullable<System.Guid> logical_record_parent_rowguid { get; set; }
        public byte[] logical_record_lineage { get; set; }
    }
}