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
    
    public partial class MSmerge_identity_range
    {
        public System.Guid subid { get; set; }
        public System.Guid artid { get; set; }
        public Nullable<decimal> range_begin { get; set; }
        public Nullable<decimal> range_end { get; set; }
        public Nullable<decimal> next_range_begin { get; set; }
        public Nullable<decimal> next_range_end { get; set; }
        public bool is_pub_range { get; set; }
        public Nullable<decimal> max_used { get; set; }
    }
}
