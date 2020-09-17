using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Lazada.Models;
namespace Lazada.Controllers
{
    public class HomeController : Controller
    {
        QL_LAZADA_MN db = new QL_LAZADA_MN();
        QL_LAZADA_MT dbmt = new QL_LAZADA_MT();
        QL_LAZADA_MB dbmb = new QL_LAZADA_MB();
        public ActionResult Index(string makv)
        {

            if (makv == "KV001")
            {
                Session["makv"] = "KV001";
                return View(db.SANPHAMs.ToList());
            }
            else if (makv == "KV002")
            {
                Session["makv"] = "KV002";
                return View(dbmt.SANPHAMs.ToList());
            }
            else
            {
                Session["makv"] = "KV003";
                return View(dbmb.SANPHAMs.ToList());
            }
        }

        public ActionResult LoaiHang()
        {
            return PartialView(db.LOAIHANGs.ToList());
        }

        public ActionResult Khuvuc( string makv)
        {
            
            if(makv == "KV001")
            { 
                return View(db.SANPHAMs.ToList());
            }
            else if(makv == "KV002")
            {
                return View(dbmt.SANPHAMs.ToList());
            }
            else
            {
                return View(dbmb.SANPHAMs.ToList());
            }
        }
        public ActionResult CTSANPHAM(string masp)
        {
            if(Session["makv"].ToString()=="KV001")
            {

                var all_sp = from sp in db.SANPHAMs
                             where sp.MASP == masp
                             select sp;
                return View(all_sp);
            }  
            else if(Session["makv"].ToString() == "KV002")
            {
                var all_sp = from sp in dbmt.SANPHAMs
                             where sp.MASP == masp
                             select sp;
                return View(all_sp);
            } 
            else
            {
                var all_sp = from sp in dbmb.SANPHAMs
                             where sp.MASP == masp
                             select sp;
                return View(all_sp);
            }    
        }
    }
}