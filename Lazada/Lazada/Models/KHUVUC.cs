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
    
    public partial class KHUVUC
    {
        public KHUVUC()
        {
            this.KHACHHANGs = new HashSet<KHACHHANG>();
            this.NHACUNGCAPs = new HashSet<NHACUNGCAP>();
        }
    
        public string MAKV { get; set; }
        public string TENKV { get; set; }
        public System.Guid rowguid { get; set; }
    
        public virtual ICollection<KHACHHANG> KHACHHANGs { get; set; }
        public virtual ICollection<NHACUNGCAP> NHACUNGCAPs { get; set; }
    }
}
