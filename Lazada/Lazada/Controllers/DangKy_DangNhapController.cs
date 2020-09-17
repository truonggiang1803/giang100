using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Lazada.Models;
namespace Lazada.Controllers
{
    public class DangKy_DangNhapController : Controller
    {
        QL_LAZADA_MN dbmn = new QL_LAZADA_MN();
        QL_LAZADA_MT dbmt = new QL_LAZADA_MT();
        QL_LAZADA_MB dbmb = new QL_LAZADA_MB();
        // GET: DangKy_DangNhap

        public ActionResult DangKy()
        {
            return View();
        }
        public ActionResult DangNhap()
        {
            return View();
        }
        [HttpPost]

        public ActionResult DangKy(FormCollection collection)
        {   
            var tendn = collection["TENTK"];
            var matkhau = collection["MATKHAU"];
            var xacnhanmatkhau = collection["XACNHANMATKHAU"];
            var makv = collection["MAKV"];
            var hoten = collection["HOTEN"];
            var diachi = collection["DIACHI"];
            var sdt = collection["SDT"];
            var email = collection["EMAIL"];
            
            if (String.IsNullOrEmpty(tendn))
            {
                ViewBag.Loi1 = "Phải nhập tên đăng nhập";
            }
            else if (String.IsNullOrEmpty(matkhau))
            {
                ViewBag.Loi2 = "Phải nhập mật khẩu";
            }
            else if (matkhau != xacnhanmatkhau)
            {
                ViewBag.Loi3 = "Mật khẩu không trùng khớp";
            }
            else if (String.IsNullOrEmpty(hoten))
            {
                ViewBag.Loi5 = "Phải nhập họ tên";
            }
            else if (String.IsNullOrEmpty(diachi))
            {
                ViewBag.Loi6 = "Phải nhập địa chỉ";
            }
            else if (String.IsNullOrEmpty(sdt))
            {
                ViewBag.Loi7 = "Phải nhập số điện thoại";
            }
            else if (String.IsNullOrEmpty(email))
            {
                ViewBag.Loi8 = "Phải nhập email";
            }
            else 
            {
                if(makv=="Miền Nam")
                {
                    TK_KHACHHANG kh1 = dbmn.TK_KHACHHANG.SingleOrDefault(n => n.TENTK_KH.Equals(tendn));
                    if(kh1.TENTK_KH == tendn)
                    {
                        TK_KHACHHANG tkkh = new TK_KHACHHANG();
                        KHACHHANG kh = new KHACHHANG();
                        kh.MAKH = "KHMN" + dbmn.KHACHHANGs.Count(); ;
                        kh.MAKV = "KV001";
                        kh.MATK_KH = "TKMN" + dbmn.TK_KHACHHANG.Count(); ;
                        kh.TENKH = hoten;
                        kh.DIACHI = diachi;
                        kh.SDT = sdt;
                        kh.EMAIL = email;
                        tkkh.MATK_KH = "TKMN" + dbmn.TK_KHACHHANG.Count();
                        tkkh.TENTK_KH = tendn;
                        tkkh.MK_KH = matkhau;
                        tkkh.rowguid = System.Guid.NewGuid();
                        kh.rowguid = System.Guid.NewGuid();
                        dbmn.TK_KHACHHANG.Add(tkkh);
                        dbmn.KHACHHANGs.Add(kh);
                        dbmn.SaveChanges();
                        return RedirectToAction("DangNhap", "DangKy_DangNhap");
                    }
                    
                } 
                else if(makv == "Miền Trung")
                {
                    TK_KHACHHANG tkkh = new TK_KHACHHANG();
                    KHACHHANG kh = new KHACHHANG();
                    kh.MAKH = "KHMT" + dbmn.KHACHHANGs.Count(); ;
                    kh.MAKV = "KV002";
                    kh.MATK_KH = "TKMT" + dbmn.TK_KHACHHANG.Count(); ;
                    kh.TENKH = hoten;
                    kh.DIACHI = diachi;
                    kh.SDT = sdt;
                    kh.EMAIL = email;
                    tkkh.MATK_KH = "TKMT" + dbmn.TK_KHACHHANG.Count();
                    tkkh.TENTK_KH = tendn;
                    tkkh.MK_KH = matkhau;
                    dbmt.TK_KHACHHANG.Add(tkkh);
                    dbmt.KHACHHANGs.Add(kh);
                    dbmt.SaveChanges();
                    return RedirectToAction("DangNhap", "DangKy_DangNhap");
                }else if(makv == "Miền Bắc")
                {
                    TK_KHACHHANG tkkh = new TK_KHACHHANG();
                    KHACHHANG kh = new KHACHHANG();
                    kh.MAKH = "KHMB" + dbmn.KHACHHANGs.Count(); ;
                    kh.MAKV = "KV003";
                    kh.MATK_KH = "TKMB" + dbmn.TK_KHACHHANG.Count(); ;
                    kh.TENKH = hoten;
                    kh.DIACHI = diachi;
                    kh.SDT = sdt;
                    kh.EMAIL = email;
                    tkkh.MATK_KH = "TKMB" + dbmn.TK_KHACHHANG.Count();
                    tkkh.TENTK_KH = tendn;
                    tkkh.MK_KH = matkhau;
                    dbmb.TK_KHACHHANG.Add(tkkh);
                    dbmb.KHACHHANGs.Add(kh);
                    dbmb.SaveChanges();
                    return RedirectToAction("DangNhap", "DangKy_DangNhap");
                }
            } 
                return View();
        }
        [HttpPost]
        public ActionResult DangNhap(FormCollection collection)
        {
            var tendn = collection["TENTK"];
            var matkhau = collection["MATKHAU"];

            if (String.IsNullOrEmpty(tendn))
            {
                ViewBag.Loi1 = "Phải nhập tên đăng nhập";
            }
            else if (String.IsNullOrEmpty(matkhau))
            {
                ViewBag.Loi2 = "Phải nhập mật khẩu";
            }
            else
            {
                QL_LAZADA_MN dbmn = new QL_LAZADA_MN();               
                TK_KHACHHANG kh = dbmn.TK_KHACHHANG.SingleOrDefault(n => n.TENTK_KH.Equals(tendn) && n.MK_KH.Equals(matkhau));
                //TK_NCC ad = dbmn.TK_NCC.SingleOrDefault(n => n.TENTK_NCC.Equals(tendn) && n.MK_KH.Equals(matkhau));
                if(kh != null)
                {
                    ViewBag.Thongbao = "Chúc mừng đăng nhập thành công";
                    Session["Taikhoan"] = kh;
                    KHACHHANG username = dbmn.KHACHHANGs.SingleOrDefault(n => n.MATK_KH.Equals(kh.MATK_KH));
                    Session["Tentk"] = username.TENKH;
                    Session["matk"] = kh.MATK_KH;
                    Session["makh"] = username.MAKH;
                    Session["makv"] = "KV001";
                    Session["diachi"] = username.DIACHI;
                    return RedirectToAction("Index", "Home",new {@makv = "KV001" });
                }
                else
                {
                    QL_LAZADA_MT dbmt = new QL_LAZADA_MT();
                    TK_KHACHHANG khmt = dbmt.TK_KHACHHANG.SingleOrDefault(n => n.TENTK_KH.Equals(tendn) && n.MK_KH.Equals(matkhau));
                    //TK_NCC ad = dbmn.TK_NCC.SingleOrDefault(n => n.TENTK_NCC.Equals(tendn) && n.MK_KH.Equals(matkhau));
                    if(khmt != null)
                    {
                        ViewBag.Thongbao = "Chúc mừng đăng nhập thành công";
                        Session["Taikhoan"] = khmt;
                        KHACHHANG username = dbmt.KHACHHANGs.SingleOrDefault(n => n.MATK_KH.Equals(khmt.MATK_KH));
                        Session["Tentk"] = username.TENKH;
                        Session["matk"] = khmt.MATK_KH;
                        Session["makh"] = username.MAKH;
                        Session["makv"] = "KV002";
                        Session["diachi"] = username.DIACHI;
                        return RedirectToAction("Index", "Home", new { @makv = "KV002" });
                    } 
                    else
                    {
                        QL_LAZADA_MB dbmb = new QL_LAZADA_MB();
                        TK_KHACHHANG khmb = dbmb.TK_KHACHHANG.SingleOrDefault(n => n.TENTK_KH.Equals(tendn) && n.MK_KH.Equals(matkhau));
                        //TK_NCC ad = dbmn.TK_NCC.SingleOrDefault(n => n.TENTK_NCC.Equals(tendn) && n.MK_KH.Equals(matkhau));
                        if(khmb !=null)
                        {
                            ViewBag.Thongbao = "Chúc mừng đăng nhập thành công";
                            Session["Taikhoan"] = khmb;
                            KHACHHANG username = dbmb.KHACHHANGs.SingleOrDefault(n => n.MATK_KH.Equals(khmb.MATK_KH));
                            Session["Tentk"] = username.TENKH;
                            Session["matk"] = khmb.MATK_KH;
                            Session["makh"] = username.MAKH;
                            Session["makv"] = "KV003";
                            Session["diachi"] = username.DIACHI;
                            return RedirectToAction("Index", "Home", new { @makv = "KV003" });
                        }    
                        else
                        {
                            ViewBag.Thongbao = "Tên đăng nhập hoặc tài khoản không đúng";
                        }    
                    }
                }
                //if (kh != null || ad != null)
                //{
                //    if (kh != null && ad == null)
                //    {
                //        ViewBag.Thongbao = "Chúc mừng đăng nhập thành công";
                //        Session["Taikhoan"] = kh;
                //        KHACHHANG username = data.KHACHHANGs.SingleOrDefault(n => n.MATK.Equals(kh.MATK));
                //        Session["Tentk"] = username.TENKH;
                //        Session["matk"] = kh.MATK;
                //        Session["makh"] = username.MAKH;
                //        return RedirectToAction("Home", "Home");

                    //    }
                    //    if (kh == null && ad != null)
                    //    {
                    //        ViewBag.Thongbao = "Đăng nhập thành công";
                    //        Session["Admin"] = ad;
                    //        Session["quyen"] = ad.TENQ;
                    //        //return RedirectToAction("Home", "Home");
                    //        return RedirectToAction("Homequanly", "Admin");
                    //    }
                    //}
                //else
                //    ViewBag.Thongbao = "Tên đăng nhập hoặc tài khoản không đúng";
            }

            return View();
        }
        public ActionResult DangXuat()
        {
            if (Session["Taikhoan"] != null)
            {
                Session["Taikhoan"] = null;
                Session["Tentk"] = null;
                Session["Giohang"] = null;
                return RedirectToAction("Index", "Home");
            }
            else if (Session["Admin"] != null)
            {
                Session["Admin"] = null;
                return RedirectToAction("Home", "Home");
            }
            else
            {
                return RedirectToAction("DangNhap", "DangKy_DangNhap");
            }
        }
        public PartialViewResult TaiKhoan()
        {
            if (Session["Tenkh"] == null)
                Session["Tenkh"] = " quý khách";
            return PartialView();
        }
    }
}