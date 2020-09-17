SET QUOTED_IDENTIFIER ON

go

-- these are subscriber side procs
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


go

-- drop all the procedures first
if object_id('MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B','P') is not NULL
    drop procedure MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B
if object_id('MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch','P') is not NULL
    drop procedure MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch
if object_id('MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B','P') is not NULL
    drop procedure MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B
if object_id('MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch','P') is not NULL
    drop procedure MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch
if object_id('MSmerge_del_sp_D6E4E45B646442AC5FF3F1A665864D7B','P') is not NULL
    drop procedure MSmerge_del_sp_D6E4E45B646442AC5FF3F1A665864D7B
if object_id('MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B','P') is not NULL
    drop procedure MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B
if object_id('MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B_metadata','P') is not NULL
    drop procedure MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B_metadata
if object_id('MSmerge_cft_sp_D6E4E45B646442AC5FF3F1A665864D7B','P') is not NULL
    drop procedure MSmerge_cft_sp_D6E4E45B646442AC5FF3F1A665864D7B


go
create procedure dbo.[MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B] (@rowguid uniqueidentifier, 
            @generation bigint, @lineage varbinary(311),  @colv varbinary(1) 
, 
        @p1 varchar(10)
, 
        @p2 varchar(10)
, 
        @p3 varchar(10)
, 
        @p4 nvarchar(50)
, 
        @p5 int
, 
        @p6 nvarchar(50)
, 
        @p7 int
, 
        @p8 varchar(50)
, 
        @p9 nvarchar(max)
, 
        @p10 nvarchar(50)
, 
        @p11 nvarchar(50)
, 
        @p12 nvarchar(50)
, 
        @p13 uniqueidentifier
,@metadata_type tinyint = NULL, @lineage_old varbinary(311) = NULL, @compatlevel int = 10 
) as
    declare @errcode    int
    declare @retcode    int
    declare @rowcount   int
    declare @error      int
    declare @tablenick  int
    declare @started_transaction bit
    declare @publication_number smallint
    
    set nocount on

    select @started_transaction = 0
    select @publication_number = 3

    set @errcode= 0
    select @tablenick= 49871000
    
    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin
        RAISERROR (14126, 11, -1)
        return 4
    end



    declare @resend int

    set @resend = 0 

    if @@trancount = 0 
    begin
        begin transaction
        select @started_transaction = 1
    end
    if @metadata_type = 1 or @metadata_type = 5
    begin
        if @compatlevel < 90 and @lineage_old is not null
            set @lineage_old= {fn LINEAGE_80_TO_90(@lineage_old)}
        -- check meta consistency
        if not exists (select * from dbo.MSmerge_tombstone where tablenick = @tablenick and rowguid = @rowguid and
                        lineage = @lineage_old)
        begin
            set @errcode= 2
-- DEBUG            insert into MSmerge_debug 
-- DEBUG                (okay, artnick, rowguid, type, successcode, generation_new, lineage_old, lineage_new, twhen, comment)
-- DEBUG                values (1, @tablenick, @rowguid, @metadata_type, @errcode, @generation, @lineage_old, @lineage, getdate(), 'sp_ins')
            goto Failure
        end
    end
    -- set row meta data
    
        exec @retcode= sys.sp_MSsetrowmetadata 
            @tablenick, @rowguid, @generation, 
            @lineage, @colv, 2, @resend OUTPUT,
            @compatlevel, 1, '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'
        if @retcode<>0 or @@ERROR<>0
        begin
            set @errcode= 0
            goto Failure
        end 
    insert into [dbo].[SANPHAM] (
[MASP]
, 
        [MANCC]
, 
        [MALOAI]
, 
        [TENSP]
, 
        [DONGIA]
, 
        [DVT]
, 
        [SOLUONG]
, 
        [ANH]
, 
        [MOTA]
, 
        [KICHTHUOC]
, 
        [TRONGLUONG]
, 
        [MAUSAC]
, 
        [rowguid]
) values (
@p1
, 
        @p2
, 
        @p3
, 
        @p4
, 
        @p5
, 
        @p6
, 
        @p7
, 
        @p8
, 
        @p9
, 
        @p10
, 
        @p11
, 
        @p12
, 
        @p13
)
        select @rowcount= @@rowcount, @error= @@error
        if (@rowcount <> 1)
        begin
            set @errcode= 3
            goto Failure
        end


    -- set row meta data
    if @resend > 0  
        update dbo.MSmerge_contents set generation = 0, partchangegen = 0 
            where rowguid = @rowguid and tablenick = @tablenick 

    if @started_transaction = 1
        commit tran
    

    delete from dbo.MSmerge_metadataaction_request
        where tablenick=@tablenick and rowguid=@rowguid

    -- DEBUG    insert into MSmerge_debug 
    -- DEBUG        (okay, artnick, rowguid, type, successcode, generation_new, lineage_old, lineage_new, twhen, comment) 
    -- DEBUG        values (0, @tablenick, @rowguid, @metadata_type, 1, @generation, @lineage_old, @lineage, getdate(), 'sp_ins, @resend=' + convert(nchar(1), @resend))

    return(1)

Failure:
    if @started_transaction = 1
        rollback tran
    -- DEBUG    insert into MSmerge_debug 
    -- DEBUG        (okay, artnick, rowguid, type, successcode, generation_new, lineage_old, lineage_new, twhen, comment) 
    -- DEBUG        values (1, @tablenick, @rowguid, @metadata_type, @errcode, @generation, @lineage_old, @lineage, getdate(), 'sp_ins, @resend=' + convert(nchar(1), @resend))

    


    declare @REPOLEExtErrorDupKey            int
    declare @REPOLEExtErrorDupUniqueIndex    int

    set @REPOLEExtErrorDupKey= 2627
    set @REPOLEExtErrorDupUniqueIndex= 2601
    
    if @error in (@REPOLEExtErrorDupUniqueIndex, @REPOLEExtErrorDupKey)
    begin
        update mc
            set mc.generation= 0
            from dbo.MSmerge_contents mc join [dbo].[SANPHAM] t on mc.rowguid=t.rowguidcol
            where
                mc.tablenick = 49871000 and
                (

                        (t.[MASP]=@p1)

                        )
            end

    return(@errcode)
    

go
Create procedure dbo.[MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B] (@rowguid uniqueidentifier, @setbm varbinary(125) = NULL,
        @metadata_type tinyint, @lineage_old varbinary(311), @generation bigint,
        @lineage_new varbinary(311), @colv varbinary(1) 
,
        @p1 varchar(10) = NULL 
,
        @p2 varchar(10) = NULL 
,
        @p3 varchar(10) = NULL 
,
        @p4 nvarchar(50) = NULL 
,
        @p5 int = NULL 
,
        @p6 nvarchar(50) = NULL 
,
        @p7 int = NULL 
,
        @p8 varchar(50) = NULL 
,
        @p9 nvarchar(max) = NULL 
,
        @p10 nvarchar(50) = NULL 
,
        @p11 nvarchar(50) = NULL 
,
        @p12 nvarchar(50) = NULL 
,
        @p13 uniqueidentifier = NULL 
, @compatlevel int = 10 
)
as
    declare @match int 

    declare @fset int
    declare @errcode int
    declare @retcode smallint
    declare @rowcount int
    declare @error int
    declare @hasperm bit
    declare @tablenick int
    declare @started_transaction bit
    declare @indexing_column_updated bit
    declare @publication_number smallint

    set nocount on

    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin
        RAISERROR (14126, 11, -1)
        return 4
    end

    select @started_transaction = 0
    select @publication_number = 3
    select @tablenick = 49871000

    if is_member('db_owner') = 1
        select @hasperm = 1
    else
        select @hasperm = 0

    select @indexing_column_updated = 0

    declare @l1 varchar(10)

    declare @l2 varchar(10)

    declare @l3 varchar(10)

    if @@trancount = 0
    begin
        begin transaction sub
        select @started_transaction = 1
    end


    select 

        @l1 = [MASP]
, 
        @l2 = [MANCC]
, 
        @l3 = [MALOAI]
        from [dbo].[SANPHAM] where rowguidcol = @rowguid
    set @match = NULL


    if convert(varbinary(10), @p1)
            = convert(varbinary(10), @l1)
        set @fset = 0
    else if ( @l1 is null and @p1 is null) 
        set @fset = 0
    else if @p1 is not null
        set @fset = 1
    else if @setbm = 0x0
        set @fset = 0
    else
        exec @fset = sys.sp_MStestbit @setbm, 1
    if @fset <> 0
    begin

        if @match is NULL
        begin
            if @metadata_type = 3
            begin
                update [dbo].[SANPHAM] set [MASP] = @p1 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                   not exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000)
            end
            else if @metadata_type = 2
            begin
                update [dbo].[SANPHAM] set [MASP] = @p1 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                      exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000 and
                                      c.lineage = @lineage_old)
            end
            else
            begin
                set @errcode=2
                goto Failure
            end
        end
        else
        begin
            update [dbo].[SANPHAM] set [MASP] = @p1 
                where rowguidcol = @rowguid
        end
        select @rowcount= @@rowcount, @error= @@error
        if (@rowcount <> 1)
        begin
            set @errcode= 3
            goto Failure
        end
        select @match = 1
    end 

    if convert(varbinary(10), @p2)
            = convert(varbinary(10), @l2)
        set @fset = 0
    else if ( @l2 is null and @p2 is null) 
        set @fset = 0
    else if @p2 is not null
        set @fset = 1
    else if @setbm = 0x0
        set @fset = 0
    else
        exec @fset = sys.sp_MStestbit @setbm, 2
    if @fset <> 0
    begin

        if @match is NULL
        begin
            if @metadata_type = 3
            begin
                update [dbo].[SANPHAM] set [MANCC] = @p2 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                   not exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000)
            end
            else if @metadata_type = 2
            begin
                update [dbo].[SANPHAM] set [MANCC] = @p2 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                      exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000 and
                                      c.lineage = @lineage_old)
            end
            else
            begin
                set @errcode=2
                goto Failure
            end
        end
        else
        begin
            update [dbo].[SANPHAM] set [MANCC] = @p2 
                where rowguidcol = @rowguid
        end
        select @rowcount= @@rowcount, @error= @@error
        if (@rowcount <> 1)
        begin
            set @errcode= 3
            goto Failure
        end
        select @match = 1
    end 

    if convert(varbinary(10), @p3)
            = convert(varbinary(10), @l3)
        set @fset = 0
    else if ( @l3 is null and @p3 is null) 
        set @fset = 0
    else if @p3 is not null
        set @fset = 1
    else if @setbm = 0x0
        set @fset = 0
    else
        exec @fset = sys.sp_MStestbit @setbm, 3
    if @fset <> 0
    begin

        if @match is NULL
        begin
            if @metadata_type = 3
            begin
                update [dbo].[SANPHAM] set [MALOAI] = @p3 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                   not exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000)
            end
            else if @metadata_type = 2
            begin
                update [dbo].[SANPHAM] set [MALOAI] = @p3 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                      exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000 and
                                      c.lineage = @lineage_old)
            end
            else
            begin
                set @errcode=2
                goto Failure
            end
        end
        else
        begin
            update [dbo].[SANPHAM] set [MALOAI] = @p3 
                where rowguidcol = @rowguid
        end
        select @rowcount= @@rowcount, @error= @@error
        if (@rowcount <> 1)
        begin
            set @errcode= 3
            goto Failure
        end
        select @match = 1
    end 

    if @p9 is not null
        set @fset = 1
    else    
        exec @fset = sys.sp_MStestbit @setbm, 9
    if @fset <> 0
    begin

        if @match is NULL
        begin
            if @metadata_type = 3
            begin
                update [dbo].[SANPHAM] set [MOTA] = @p9 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                   not exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000)
            end
            else if @metadata_type = 2
            begin
                update [dbo].[SANPHAM] set [MOTA] = @p9 
                from [dbo].[SANPHAM] t 
                where t.[rowguid] = @rowguid and
                      exists (select 1 from dbo.MSmerge_contents c with (rowlock)
                                where c.rowguid = @rowguid and 
                                      c.tablenick = 49871000 and
                                      c.lineage = @lineage_old)
            end
            else
            begin
                set @errcode=2
                goto Failure
            end
        end
        else
        begin
            update [dbo].[SANPHAM] set [MOTA] = @p9 
                where rowguidcol = @rowguid
        end
        select @rowcount= @@rowcount, @error= @@error
        if (@rowcount <> 1)
        begin
            set @errcode= 3
            goto Failure
        end
        select @match = 1
    end 

    if @match is NULL
    begin
        update [dbo].[SANPHAM] set 

            [TENSP] = case when @p4 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 4) <> 0 then @p4 else t.[TENSP] end) else @p4 end 
,

            [DONGIA] = case when @p5 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 5) <> 0 then @p5 else t.[DONGIA] end) else @p5 end 
,

            [DVT] = case when @p6 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 6) <> 0 then @p6 else t.[DVT] end) else @p6 end 
,

            [SOLUONG] = case when @p7 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 7) <> 0 then @p7 else t.[SOLUONG] end) else @p7 end 
,

            [ANH] = case when @p8 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 8) <> 0 then @p8 else t.[ANH] end) else @p8 end 
,

            [KICHTHUOC] = case when @p10 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 10) <> 0 then @p10 else t.[KICHTHUOC] end) else @p10 end 
,

            [TRONGLUONG] = case when @p11 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 11) <> 0 then @p11 else t.[TRONGLUONG] end) else @p11 end 
,

            [MAUSAC] = case when @p12 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 12) <> 0 then @p12 else t.[MAUSAC] end) else @p12 end 
 
         from [dbo].[SANPHAM] t 
            left outer join dbo.MSmerge_contents c with (rowlock)
                on c.rowguid = t.[rowguid] and 
                   c.tablenick = 49871000 and
                   t.[rowguid] = @rowguid
         where t.[rowguid] = @rowguid and
         ((@match is not NULL and @match = 1) or 
          ((@metadata_type = 3 and c.rowguid is NULL) or
           (@metadata_type = 2 and c.rowguid is not NULL and c.lineage = @lineage_old)))

        select @rowcount= @@rowcount, @error= @@error
    end
    else
    begin
        update [dbo].[SANPHAM] set 

            [TENSP] = case when @p4 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 4) <> 0 then @p4 else t.[TENSP] end) else @p4 end 
,

            [DONGIA] = case when @p5 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 5) <> 0 then @p5 else t.[DONGIA] end) else @p5 end 
,

            [DVT] = case when @p6 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 6) <> 0 then @p6 else t.[DVT] end) else @p6 end 
,

            [SOLUONG] = case when @p7 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 7) <> 0 then @p7 else t.[SOLUONG] end) else @p7 end 
,

            [ANH] = case when @p8 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 8) <> 0 then @p8 else t.[ANH] end) else @p8 end 
,

            [KICHTHUOC] = case when @p10 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 10) <> 0 then @p10 else t.[KICHTHUOC] end) else @p10 end 
,

            [TRONGLUONG] = case when @p11 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 11) <> 0 then @p11 else t.[TRONGLUONG] end) else @p11 end 
,

            [MAUSAC] = case when @p12 is NULL then (case when sys.fn_IsBitSetInBitmask(@setbm, 12) <> 0 then @p12 else t.[MAUSAC] end) else @p12 end 
 
         from [dbo].[SANPHAM] t 
             where t.[rowguid] = @rowguid

        select @rowcount= @@rowcount, @error= @@error
    end

    if (@rowcount <> 1) or (@error <> 0)
    begin
        set @errcode= 3
        goto Failure
    end

    select @match = 1
 
    exec @retcode= sys.sp_MSsetrowmetadata 
        @tablenick, @rowguid, @generation, 
        @lineage_new, @colv, 2, NULL, 
        @compatlevel, 0, '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'
    if @retcode<>0 or @@ERROR<>0
    begin
        set @errcode= 3
        goto Failure
    end 

delete from dbo.MSmerge_metadataaction_request
    where tablenick=@tablenick and rowguid=@rowguid

    if @started_transaction = 1
        commit transaction

-- DEBUG    insert into MSmerge_debug 
-- DEBUG        (okay, artnick, rowguid, type, successcode, generation_new, lineage_old, lineage_new, twhen, comment)
-- DEBUG        values (0, @tablenick, @rowguid, @metadata_type, 1, @generation, @lineage_old, @lineage_new, getdate(), 'sp_upd')

    return(1)

Failure:
    --rollback transaction sub
    --commit transaction
    if @started_transaction = 1    
        rollback transaction
-- DEBUG    insert into MSmerge_debug 
-- DEBUG        (okay, artnick, rowguid, type, successcode, generation_new, lineage_old, lineage_new, twhen, comment)
-- DEBUG        values (1, @tablenick, @rowguid, @metadata_type, @errcode, @generation, @lineage_old, @lineage_new, getdate(), 'sp_upd')




    declare @REPOLEExtErrorDupKey            int
    declare @REPOLEExtErrorDupUniqueIndex    int

    set @REPOLEExtErrorDupKey= 2627
    set @REPOLEExtErrorDupUniqueIndex= 2601
    
    if @error in (@REPOLEExtErrorDupUniqueIndex, @REPOLEExtErrorDupKey)
    begin
        update mc
            set mc.generation= 0
            from dbo.MSmerge_contents mc join [dbo].[SANPHAM] t on mc.rowguid=t.rowguidcol
            where
                mc.tablenick = 49871000 and
                (

                        (t.[MASP]=@p1)

                        )
            end

    return @errcode

go

create procedure dbo.[MSmerge_del_sp_D6E4E45B646442AC5FF3F1A665864D7B]
(
    @rowstobedeleted int, 
    @partition_id int = NULL 
,
    @rowguid1 uniqueidentifier = NULL,
    @metadata_type1 tinyint = NULL,
    @generation1 bigint = NULL,
    @lineage_old1 varbinary(311) = NULL,
    @lineage_new1 varbinary(311) = NULL,
    @rowguid2 uniqueidentifier = NULL,
    @metadata_type2 tinyint = NULL,
    @generation2 bigint = NULL,
    @lineage_old2 varbinary(311) = NULL,
    @lineage_new2 varbinary(311) = NULL,
    @rowguid3 uniqueidentifier = NULL,
    @metadata_type3 tinyint = NULL,
    @generation3 bigint = NULL,
    @lineage_old3 varbinary(311) = NULL,
    @lineage_new3 varbinary(311) = NULL,
    @rowguid4 uniqueidentifier = NULL,
    @metadata_type4 tinyint = NULL,
    @generation4 bigint = NULL,
    @lineage_old4 varbinary(311) = NULL,
    @lineage_new4 varbinary(311) = NULL,
    @rowguid5 uniqueidentifier = NULL,
    @metadata_type5 tinyint = NULL,
    @generation5 bigint = NULL,
    @lineage_old5 varbinary(311) = NULL,
    @lineage_new5 varbinary(311) = NULL,
    @rowguid6 uniqueidentifier = NULL,
    @metadata_type6 tinyint = NULL,
    @generation6 bigint = NULL,
    @lineage_old6 varbinary(311) = NULL,
    @lineage_new6 varbinary(311) = NULL,
    @rowguid7 uniqueidentifier = NULL,
    @metadata_type7 tinyint = NULL,
    @generation7 bigint = NULL,
    @lineage_old7 varbinary(311) = NULL,
    @lineage_new7 varbinary(311) = NULL,
    @rowguid8 uniqueidentifier = NULL,
    @metadata_type8 tinyint = NULL,
    @generation8 bigint = NULL,
    @lineage_old8 varbinary(311) = NULL,
    @lineage_new8 varbinary(311) = NULL,
    @rowguid9 uniqueidentifier = NULL,
    @metadata_type9 tinyint = NULL,
    @generation9 bigint = NULL,
    @lineage_old9 varbinary(311) = NULL,
    @lineage_new9 varbinary(311) = NULL,
    @rowguid10 uniqueidentifier = NULL,
    @metadata_type10 tinyint = NULL,
    @generation10 bigint = NULL,
    @lineage_old10 varbinary(311) = NULL,
    @lineage_new10 varbinary(311) = NULL
,
    @rowguid11 uniqueidentifier = NULL,
    @metadata_type11 tinyint = NULL,
    @generation11 bigint = NULL,
    @lineage_old11 varbinary(311) = NULL,
    @lineage_new11 varbinary(311) = NULL,
    @rowguid12 uniqueidentifier = NULL,
    @metadata_type12 tinyint = NULL,
    @generation12 bigint = NULL,
    @lineage_old12 varbinary(311) = NULL,
    @lineage_new12 varbinary(311) = NULL,
    @rowguid13 uniqueidentifier = NULL,
    @metadata_type13 tinyint = NULL,
    @generation13 bigint = NULL,
    @lineage_old13 varbinary(311) = NULL,
    @lineage_new13 varbinary(311) = NULL,
    @rowguid14 uniqueidentifier = NULL,
    @metadata_type14 tinyint = NULL,
    @generation14 bigint = NULL,
    @lineage_old14 varbinary(311) = NULL,
    @lineage_new14 varbinary(311) = NULL,
    @rowguid15 uniqueidentifier = NULL,
    @metadata_type15 tinyint = NULL,
    @generation15 bigint = NULL,
    @lineage_old15 varbinary(311) = NULL,
    @lineage_new15 varbinary(311) = NULL,
    @rowguid16 uniqueidentifier = NULL,
    @metadata_type16 tinyint = NULL,
    @generation16 bigint = NULL,
    @lineage_old16 varbinary(311) = NULL,
    @lineage_new16 varbinary(311) = NULL,
    @rowguid17 uniqueidentifier = NULL,
    @metadata_type17 tinyint = NULL,
    @generation17 bigint = NULL,
    @lineage_old17 varbinary(311) = NULL,
    @lineage_new17 varbinary(311) = NULL,
    @rowguid18 uniqueidentifier = NULL,
    @metadata_type18 tinyint = NULL,
    @generation18 bigint = NULL,
    @lineage_old18 varbinary(311) = NULL,
    @lineage_new18 varbinary(311) = NULL,
    @rowguid19 uniqueidentifier = NULL,
    @metadata_type19 tinyint = NULL,
    @generation19 bigint = NULL,
    @lineage_old19 varbinary(311) = NULL,
    @lineage_new19 varbinary(311) = NULL,
    @rowguid20 uniqueidentifier = NULL,
    @metadata_type20 tinyint = NULL,
    @generation20 bigint = NULL,
    @lineage_old20 varbinary(311) = NULL,
    @lineage_new20 varbinary(311) = NULL
,
    @rowguid21 uniqueidentifier = NULL,
    @metadata_type21 tinyint = NULL,
    @generation21 bigint = NULL,
    @lineage_old21 varbinary(311) = NULL,
    @lineage_new21 varbinary(311) = NULL,
    @rowguid22 uniqueidentifier = NULL,
    @metadata_type22 tinyint = NULL,
    @generation22 bigint = NULL,
    @lineage_old22 varbinary(311) = NULL,
    @lineage_new22 varbinary(311) = NULL,
    @rowguid23 uniqueidentifier = NULL,
    @metadata_type23 tinyint = NULL,
    @generation23 bigint = NULL,
    @lineage_old23 varbinary(311) = NULL,
    @lineage_new23 varbinary(311) = NULL,
    @rowguid24 uniqueidentifier = NULL,
    @metadata_type24 tinyint = NULL,
    @generation24 bigint = NULL,
    @lineage_old24 varbinary(311) = NULL,
    @lineage_new24 varbinary(311) = NULL,
    @rowguid25 uniqueidentifier = NULL,
    @metadata_type25 tinyint = NULL,
    @generation25 bigint = NULL,
    @lineage_old25 varbinary(311) = NULL,
    @lineage_new25 varbinary(311) = NULL,
    @rowguid26 uniqueidentifier = NULL,
    @metadata_type26 tinyint = NULL,
    @generation26 bigint = NULL,
    @lineage_old26 varbinary(311) = NULL,
    @lineage_new26 varbinary(311) = NULL,
    @rowguid27 uniqueidentifier = NULL,
    @metadata_type27 tinyint = NULL,
    @generation27 bigint = NULL,
    @lineage_old27 varbinary(311) = NULL,
    @lineage_new27 varbinary(311) = NULL,
    @rowguid28 uniqueidentifier = NULL,
    @metadata_type28 tinyint = NULL,
    @generation28 bigint = NULL,
    @lineage_old28 varbinary(311) = NULL,
    @lineage_new28 varbinary(311) = NULL,
    @rowguid29 uniqueidentifier = NULL,
    @metadata_type29 tinyint = NULL,
    @generation29 bigint = NULL,
    @lineage_old29 varbinary(311) = NULL,
    @lineage_new29 varbinary(311) = NULL,
    @rowguid30 uniqueidentifier = NULL,
    @metadata_type30 tinyint = NULL,
    @generation30 bigint = NULL,
    @lineage_old30 varbinary(311) = NULL,
    @lineage_new30 varbinary(311) = NULL
,
    @rowguid31 uniqueidentifier = NULL,
    @metadata_type31 tinyint = NULL,
    @generation31 bigint = NULL,
    @lineage_old31 varbinary(311) = NULL,
    @lineage_new31 varbinary(311) = NULL,
    @rowguid32 uniqueidentifier = NULL,
    @metadata_type32 tinyint = NULL,
    @generation32 bigint = NULL,
    @lineage_old32 varbinary(311) = NULL,
    @lineage_new32 varbinary(311) = NULL,
    @rowguid33 uniqueidentifier = NULL,
    @metadata_type33 tinyint = NULL,
    @generation33 bigint = NULL,
    @lineage_old33 varbinary(311) = NULL,
    @lineage_new33 varbinary(311) = NULL,
    @rowguid34 uniqueidentifier = NULL,
    @metadata_type34 tinyint = NULL,
    @generation34 bigint = NULL,
    @lineage_old34 varbinary(311) = NULL,
    @lineage_new34 varbinary(311) = NULL,
    @rowguid35 uniqueidentifier = NULL,
    @metadata_type35 tinyint = NULL,
    @generation35 bigint = NULL,
    @lineage_old35 varbinary(311) = NULL,
    @lineage_new35 varbinary(311) = NULL,
    @rowguid36 uniqueidentifier = NULL,
    @metadata_type36 tinyint = NULL,
    @generation36 bigint = NULL,
    @lineage_old36 varbinary(311) = NULL,
    @lineage_new36 varbinary(311) = NULL,
    @rowguid37 uniqueidentifier = NULL,
    @metadata_type37 tinyint = NULL,
    @generation37 bigint = NULL,
    @lineage_old37 varbinary(311) = NULL,
    @lineage_new37 varbinary(311) = NULL,
    @rowguid38 uniqueidentifier = NULL,
    @metadata_type38 tinyint = NULL,
    @generation38 bigint = NULL,
    @lineage_old38 varbinary(311) = NULL,
    @lineage_new38 varbinary(311) = NULL,
    @rowguid39 uniqueidentifier = NULL,
    @metadata_type39 tinyint = NULL,
    @generation39 bigint = NULL,
    @lineage_old39 varbinary(311) = NULL,
    @lineage_new39 varbinary(311) = NULL,
    @rowguid40 uniqueidentifier = NULL,
    @metadata_type40 tinyint = NULL,
    @generation40 bigint = NULL,
    @lineage_old40 varbinary(311) = NULL,
    @lineage_new40 varbinary(311) = NULL
,
    @rowguid41 uniqueidentifier = NULL,
    @metadata_type41 tinyint = NULL,
    @generation41 bigint = NULL,
    @lineage_old41 varbinary(311) = NULL,
    @lineage_new41 varbinary(311) = NULL,
    @rowguid42 uniqueidentifier = NULL,
    @metadata_type42 tinyint = NULL,
    @generation42 bigint = NULL,
    @lineage_old42 varbinary(311) = NULL,
    @lineage_new42 varbinary(311) = NULL,
    @rowguid43 uniqueidentifier = NULL,
    @metadata_type43 tinyint = NULL,
    @generation43 bigint = NULL,
    @lineage_old43 varbinary(311) = NULL,
    @lineage_new43 varbinary(311) = NULL,
    @rowguid44 uniqueidentifier = NULL,
    @metadata_type44 tinyint = NULL,
    @generation44 bigint = NULL,
    @lineage_old44 varbinary(311) = NULL,
    @lineage_new44 varbinary(311) = NULL,
    @rowguid45 uniqueidentifier = NULL,
    @metadata_type45 tinyint = NULL,
    @generation45 bigint = NULL,
    @lineage_old45 varbinary(311) = NULL,
    @lineage_new45 varbinary(311) = NULL,
    @rowguid46 uniqueidentifier = NULL,
    @metadata_type46 tinyint = NULL,
    @generation46 bigint = NULL,
    @lineage_old46 varbinary(311) = NULL,
    @lineage_new46 varbinary(311) = NULL,
    @rowguid47 uniqueidentifier = NULL,
    @metadata_type47 tinyint = NULL,
    @generation47 bigint = NULL,
    @lineage_old47 varbinary(311) = NULL,
    @lineage_new47 varbinary(311) = NULL,
    @rowguid48 uniqueidentifier = NULL,
    @metadata_type48 tinyint = NULL,
    @generation48 bigint = NULL,
    @lineage_old48 varbinary(311) = NULL,
    @lineage_new48 varbinary(311) = NULL,
    @rowguid49 uniqueidentifier = NULL,
    @metadata_type49 tinyint = NULL,
    @generation49 bigint = NULL,
    @lineage_old49 varbinary(311) = NULL,
    @lineage_new49 varbinary(311) = NULL,
    @rowguid50 uniqueidentifier = NULL,
    @metadata_type50 tinyint = NULL,
    @generation50 bigint = NULL,
    @lineage_old50 varbinary(311) = NULL,
    @lineage_new50 varbinary(311) = NULL
,
    @rowguid51 uniqueidentifier = NULL,
    @metadata_type51 tinyint = NULL,
    @generation51 bigint = NULL,
    @lineage_old51 varbinary(311) = NULL,
    @lineage_new51 varbinary(311) = NULL,
    @rowguid52 uniqueidentifier = NULL,
    @metadata_type52 tinyint = NULL,
    @generation52 bigint = NULL,
    @lineage_old52 varbinary(311) = NULL,
    @lineage_new52 varbinary(311) = NULL,
    @rowguid53 uniqueidentifier = NULL,
    @metadata_type53 tinyint = NULL,
    @generation53 bigint = NULL,
    @lineage_old53 varbinary(311) = NULL,
    @lineage_new53 varbinary(311) = NULL,
    @rowguid54 uniqueidentifier = NULL,
    @metadata_type54 tinyint = NULL,
    @generation54 bigint = NULL,
    @lineage_old54 varbinary(311) = NULL,
    @lineage_new54 varbinary(311) = NULL,
    @rowguid55 uniqueidentifier = NULL,
    @metadata_type55 tinyint = NULL,
    @generation55 bigint = NULL,
    @lineage_old55 varbinary(311) = NULL,
    @lineage_new55 varbinary(311) = NULL,
    @rowguid56 uniqueidentifier = NULL,
    @metadata_type56 tinyint = NULL,
    @generation56 bigint = NULL,
    @lineage_old56 varbinary(311) = NULL,
    @lineage_new56 varbinary(311) = NULL,
    @rowguid57 uniqueidentifier = NULL,
    @metadata_type57 tinyint = NULL,
    @generation57 bigint = NULL,
    @lineage_old57 varbinary(311) = NULL,
    @lineage_new57 varbinary(311) = NULL,
    @rowguid58 uniqueidentifier = NULL,
    @metadata_type58 tinyint = NULL,
    @generation58 bigint = NULL,
    @lineage_old58 varbinary(311) = NULL,
    @lineage_new58 varbinary(311) = NULL,
    @rowguid59 uniqueidentifier = NULL,
    @metadata_type59 tinyint = NULL,
    @generation59 bigint = NULL,
    @lineage_old59 varbinary(311) = NULL,
    @lineage_new59 varbinary(311) = NULL,
    @rowguid60 uniqueidentifier = NULL,
    @metadata_type60 tinyint = NULL,
    @generation60 bigint = NULL,
    @lineage_old60 varbinary(311) = NULL,
    @lineage_new60 varbinary(311) = NULL
,
    @rowguid61 uniqueidentifier = NULL,
    @metadata_type61 tinyint = NULL,
    @generation61 bigint = NULL,
    @lineage_old61 varbinary(311) = NULL,
    @lineage_new61 varbinary(311) = NULL,
    @rowguid62 uniqueidentifier = NULL,
    @metadata_type62 tinyint = NULL,
    @generation62 bigint = NULL,
    @lineage_old62 varbinary(311) = NULL,
    @lineage_new62 varbinary(311) = NULL,
    @rowguid63 uniqueidentifier = NULL,
    @metadata_type63 tinyint = NULL,
    @generation63 bigint = NULL,
    @lineage_old63 varbinary(311) = NULL,
    @lineage_new63 varbinary(311) = NULL,
    @rowguid64 uniqueidentifier = NULL,
    @metadata_type64 tinyint = NULL,
    @generation64 bigint = NULL,
    @lineage_old64 varbinary(311) = NULL,
    @lineage_new64 varbinary(311) = NULL,
    @rowguid65 uniqueidentifier = NULL,
    @metadata_type65 tinyint = NULL,
    @generation65 bigint = NULL,
    @lineage_old65 varbinary(311) = NULL,
    @lineage_new65 varbinary(311) = NULL,
    @rowguid66 uniqueidentifier = NULL,
    @metadata_type66 tinyint = NULL,
    @generation66 bigint = NULL,
    @lineage_old66 varbinary(311) = NULL,
    @lineage_new66 varbinary(311) = NULL,
    @rowguid67 uniqueidentifier = NULL,
    @metadata_type67 tinyint = NULL,
    @generation67 bigint = NULL,
    @lineage_old67 varbinary(311) = NULL,
    @lineage_new67 varbinary(311) = NULL,
    @rowguid68 uniqueidentifier = NULL,
    @metadata_type68 tinyint = NULL,
    @generation68 bigint = NULL,
    @lineage_old68 varbinary(311) = NULL,
    @lineage_new68 varbinary(311) = NULL,
    @rowguid69 uniqueidentifier = NULL,
    @metadata_type69 tinyint = NULL,
    @generation69 bigint = NULL,
    @lineage_old69 varbinary(311) = NULL,
    @lineage_new69 varbinary(311) = NULL,
    @rowguid70 uniqueidentifier = NULL,
    @metadata_type70 tinyint = NULL,
    @generation70 bigint = NULL,
    @lineage_old70 varbinary(311) = NULL,
    @lineage_new70 varbinary(311) = NULL
,
    @rowguid71 uniqueidentifier = NULL,
    @metadata_type71 tinyint = NULL,
    @generation71 bigint = NULL,
    @lineage_old71 varbinary(311) = NULL,
    @lineage_new71 varbinary(311) = NULL,
    @rowguid72 uniqueidentifier = NULL,
    @metadata_type72 tinyint = NULL,
    @generation72 bigint = NULL,
    @lineage_old72 varbinary(311) = NULL,
    @lineage_new72 varbinary(311) = NULL,
    @rowguid73 uniqueidentifier = NULL,
    @metadata_type73 tinyint = NULL,
    @generation73 bigint = NULL,
    @lineage_old73 varbinary(311) = NULL,
    @lineage_new73 varbinary(311) = NULL,
    @rowguid74 uniqueidentifier = NULL,
    @metadata_type74 tinyint = NULL,
    @generation74 bigint = NULL,
    @lineage_old74 varbinary(311) = NULL,
    @lineage_new74 varbinary(311) = NULL,
    @rowguid75 uniqueidentifier = NULL,
    @metadata_type75 tinyint = NULL,
    @generation75 bigint = NULL,
    @lineage_old75 varbinary(311) = NULL,
    @lineage_new75 varbinary(311) = NULL,
    @rowguid76 uniqueidentifier = NULL,
    @metadata_type76 tinyint = NULL,
    @generation76 bigint = NULL,
    @lineage_old76 varbinary(311) = NULL,
    @lineage_new76 varbinary(311) = NULL,
    @rowguid77 uniqueidentifier = NULL,
    @metadata_type77 tinyint = NULL,
    @generation77 bigint = NULL,
    @lineage_old77 varbinary(311) = NULL,
    @lineage_new77 varbinary(311) = NULL,
    @rowguid78 uniqueidentifier = NULL,
    @metadata_type78 tinyint = NULL,
    @generation78 bigint = NULL,
    @lineage_old78 varbinary(311) = NULL,
    @lineage_new78 varbinary(311) = NULL,
    @rowguid79 uniqueidentifier = NULL,
    @metadata_type79 tinyint = NULL,
    @generation79 bigint = NULL,
    @lineage_old79 varbinary(311) = NULL,
    @lineage_new79 varbinary(311) = NULL,
    @rowguid80 uniqueidentifier = NULL,
    @metadata_type80 tinyint = NULL,
    @generation80 bigint = NULL,
    @lineage_old80 varbinary(311) = NULL,
    @lineage_new80 varbinary(311) = NULL
,
    @rowguid81 uniqueidentifier = NULL,
    @metadata_type81 tinyint = NULL,
    @generation81 bigint = NULL,
    @lineage_old81 varbinary(311) = NULL,
    @lineage_new81 varbinary(311) = NULL,
    @rowguid82 uniqueidentifier = NULL,
    @metadata_type82 tinyint = NULL,
    @generation82 bigint = NULL,
    @lineage_old82 varbinary(311) = NULL,
    @lineage_new82 varbinary(311) = NULL,
    @rowguid83 uniqueidentifier = NULL,
    @metadata_type83 tinyint = NULL,
    @generation83 bigint = NULL,
    @lineage_old83 varbinary(311) = NULL,
    @lineage_new83 varbinary(311) = NULL,
    @rowguid84 uniqueidentifier = NULL,
    @metadata_type84 tinyint = NULL,
    @generation84 bigint = NULL,
    @lineage_old84 varbinary(311) = NULL,
    @lineage_new84 varbinary(311) = NULL,
    @rowguid85 uniqueidentifier = NULL,
    @metadata_type85 tinyint = NULL,
    @generation85 bigint = NULL,
    @lineage_old85 varbinary(311) = NULL,
    @lineage_new85 varbinary(311) = NULL,
    @rowguid86 uniqueidentifier = NULL,
    @metadata_type86 tinyint = NULL,
    @generation86 bigint = NULL,
    @lineage_old86 varbinary(311) = NULL,
    @lineage_new86 varbinary(311) = NULL,
    @rowguid87 uniqueidentifier = NULL,
    @metadata_type87 tinyint = NULL,
    @generation87 bigint = NULL,
    @lineage_old87 varbinary(311) = NULL,
    @lineage_new87 varbinary(311) = NULL,
    @rowguid88 uniqueidentifier = NULL,
    @metadata_type88 tinyint = NULL,
    @generation88 bigint = NULL,
    @lineage_old88 varbinary(311) = NULL,
    @lineage_new88 varbinary(311) = NULL,
    @rowguid89 uniqueidentifier = NULL,
    @metadata_type89 tinyint = NULL,
    @generation89 bigint = NULL,
    @lineage_old89 varbinary(311) = NULL,
    @lineage_new89 varbinary(311) = NULL,
    @rowguid90 uniqueidentifier = NULL,
    @metadata_type90 tinyint = NULL,
    @generation90 bigint = NULL,
    @lineage_old90 varbinary(311) = NULL,
    @lineage_new90 varbinary(311) = NULL
,
    @rowguid91 uniqueidentifier = NULL,
    @metadata_type91 tinyint = NULL,
    @generation91 bigint = NULL,
    @lineage_old91 varbinary(311) = NULL,
    @lineage_new91 varbinary(311) = NULL,
    @rowguid92 uniqueidentifier = NULL,
    @metadata_type92 tinyint = NULL,
    @generation92 bigint = NULL,
    @lineage_old92 varbinary(311) = NULL,
    @lineage_new92 varbinary(311) = NULL,
    @rowguid93 uniqueidentifier = NULL,
    @metadata_type93 tinyint = NULL,
    @generation93 bigint = NULL,
    @lineage_old93 varbinary(311) = NULL,
    @lineage_new93 varbinary(311) = NULL,
    @rowguid94 uniqueidentifier = NULL,
    @metadata_type94 tinyint = NULL,
    @generation94 bigint = NULL,
    @lineage_old94 varbinary(311) = NULL,
    @lineage_new94 varbinary(311) = NULL,
    @rowguid95 uniqueidentifier = NULL,
    @metadata_type95 tinyint = NULL,
    @generation95 bigint = NULL,
    @lineage_old95 varbinary(311) = NULL,
    @lineage_new95 varbinary(311) = NULL,
    @rowguid96 uniqueidentifier = NULL,
    @metadata_type96 tinyint = NULL,
    @generation96 bigint = NULL,
    @lineage_old96 varbinary(311) = NULL,
    @lineage_new96 varbinary(311) = NULL,
    @rowguid97 uniqueidentifier = NULL,
    @metadata_type97 tinyint = NULL,
    @generation97 bigint = NULL,
    @lineage_old97 varbinary(311) = NULL,
    @lineage_new97 varbinary(311) = NULL,
    @rowguid98 uniqueidentifier = NULL,
    @metadata_type98 tinyint = NULL,
    @generation98 bigint = NULL,
    @lineage_old98 varbinary(311) = NULL,
    @lineage_new98 varbinary(311) = NULL,
    @rowguid99 uniqueidentifier = NULL,
    @metadata_type99 tinyint = NULL,
    @generation99 bigint = NULL,
    @lineage_old99 varbinary(311) = NULL,
    @lineage_new99 varbinary(311) = NULL,
    @rowguid100 uniqueidentifier = NULL,
    @metadata_type100 tinyint = NULL,
    @generation100 bigint = NULL,
    @lineage_old100 varbinary(311) = NULL,
    @lineage_new100 varbinary(311) = NULL

)
as
begin


    -- this proc returns 0 to indicate error and 1 to indicate success
    declare @retcode    int
    set nocount on
    declare @rows_deleted int
    declare @rows_remaining int
    declare @error int
    declare @tomb_rows_updated int
    declare @publication_number smallint
    declare @rows_in_syncview int
        
    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin       
        RAISERROR (14126, 11, -1)
        return 0
    end
    
    select @publication_number = 3

    if @rowstobedeleted is NULL or @rowstobedeleted <= 0
        return 0

    begin tran
    save tran batchdeleteproc


    delete [dbo].[SANPHAM] with (rowlock)
    from 
    (

    select @rowguid1 as rowguid, @metadata_type1 as metadata_type, @lineage_old1 as lineage_old, @lineage_new1 as lineage_new, @generation1 as generation  union all 
    select @rowguid2 as rowguid, @metadata_type2 as metadata_type, @lineage_old2 as lineage_old, @lineage_new2 as lineage_new, @generation2 as generation  union all 
    select @rowguid3 as rowguid, @metadata_type3 as metadata_type, @lineage_old3 as lineage_old, @lineage_new3 as lineage_new, @generation3 as generation  union all 
    select @rowguid4 as rowguid, @metadata_type4 as metadata_type, @lineage_old4 as lineage_old, @lineage_new4 as lineage_new, @generation4 as generation  union all 
    select @rowguid5 as rowguid, @metadata_type5 as metadata_type, @lineage_old5 as lineage_old, @lineage_new5 as lineage_new, @generation5 as generation  union all 
    select @rowguid6 as rowguid, @metadata_type6 as metadata_type, @lineage_old6 as lineage_old, @lineage_new6 as lineage_new, @generation6 as generation  union all 
    select @rowguid7 as rowguid, @metadata_type7 as metadata_type, @lineage_old7 as lineage_old, @lineage_new7 as lineage_new, @generation7 as generation  union all 
    select @rowguid8 as rowguid, @metadata_type8 as metadata_type, @lineage_old8 as lineage_old, @lineage_new8 as lineage_new, @generation8 as generation  union all 
    select @rowguid9 as rowguid, @metadata_type9 as metadata_type, @lineage_old9 as lineage_old, @lineage_new9 as lineage_new, @generation9 as generation  union all 
    select @rowguid10 as rowguid, @metadata_type10 as metadata_type, @lineage_old10 as lineage_old, @lineage_new10 as lineage_new, @generation10 as generation 
 union all 
    select @rowguid11 as rowguid, @metadata_type11 as metadata_type, @lineage_old11 as lineage_old, @lineage_new11 as lineage_new, @generation11 as generation  union all 
    select @rowguid12 as rowguid, @metadata_type12 as metadata_type, @lineage_old12 as lineage_old, @lineage_new12 as lineage_new, @generation12 as generation  union all 
    select @rowguid13 as rowguid, @metadata_type13 as metadata_type, @lineage_old13 as lineage_old, @lineage_new13 as lineage_new, @generation13 as generation  union all 
    select @rowguid14 as rowguid, @metadata_type14 as metadata_type, @lineage_old14 as lineage_old, @lineage_new14 as lineage_new, @generation14 as generation  union all 
    select @rowguid15 as rowguid, @metadata_type15 as metadata_type, @lineage_old15 as lineage_old, @lineage_new15 as lineage_new, @generation15 as generation  union all 
    select @rowguid16 as rowguid, @metadata_type16 as metadata_type, @lineage_old16 as lineage_old, @lineage_new16 as lineage_new, @generation16 as generation  union all 
    select @rowguid17 as rowguid, @metadata_type17 as metadata_type, @lineage_old17 as lineage_old, @lineage_new17 as lineage_new, @generation17 as generation  union all 
    select @rowguid18 as rowguid, @metadata_type18 as metadata_type, @lineage_old18 as lineage_old, @lineage_new18 as lineage_new, @generation18 as generation  union all 
    select @rowguid19 as rowguid, @metadata_type19 as metadata_type, @lineage_old19 as lineage_old, @lineage_new19 as lineage_new, @generation19 as generation  union all 
    select @rowguid20 as rowguid, @metadata_type20 as metadata_type, @lineage_old20 as lineage_old, @lineage_new20 as lineage_new, @generation20 as generation 
 union all 
    select @rowguid21 as rowguid, @metadata_type21 as metadata_type, @lineage_old21 as lineage_old, @lineage_new21 as lineage_new, @generation21 as generation  union all 
    select @rowguid22 as rowguid, @metadata_type22 as metadata_type, @lineage_old22 as lineage_old, @lineage_new22 as lineage_new, @generation22 as generation  union all 
    select @rowguid23 as rowguid, @metadata_type23 as metadata_type, @lineage_old23 as lineage_old, @lineage_new23 as lineage_new, @generation23 as generation  union all 
    select @rowguid24 as rowguid, @metadata_type24 as metadata_type, @lineage_old24 as lineage_old, @lineage_new24 as lineage_new, @generation24 as generation  union all 
    select @rowguid25 as rowguid, @metadata_type25 as metadata_type, @lineage_old25 as lineage_old, @lineage_new25 as lineage_new, @generation25 as generation  union all 
    select @rowguid26 as rowguid, @metadata_type26 as metadata_type, @lineage_old26 as lineage_old, @lineage_new26 as lineage_new, @generation26 as generation  union all 
    select @rowguid27 as rowguid, @metadata_type27 as metadata_type, @lineage_old27 as lineage_old, @lineage_new27 as lineage_new, @generation27 as generation  union all 
    select @rowguid28 as rowguid, @metadata_type28 as metadata_type, @lineage_old28 as lineage_old, @lineage_new28 as lineage_new, @generation28 as generation  union all 
    select @rowguid29 as rowguid, @metadata_type29 as metadata_type, @lineage_old29 as lineage_old, @lineage_new29 as lineage_new, @generation29 as generation  union all 
    select @rowguid30 as rowguid, @metadata_type30 as metadata_type, @lineage_old30 as lineage_old, @lineage_new30 as lineage_new, @generation30 as generation 
 union all 
    select @rowguid31 as rowguid, @metadata_type31 as metadata_type, @lineage_old31 as lineage_old, @lineage_new31 as lineage_new, @generation31 as generation  union all 
    select @rowguid32 as rowguid, @metadata_type32 as metadata_type, @lineage_old32 as lineage_old, @lineage_new32 as lineage_new, @generation32 as generation  union all 
    select @rowguid33 as rowguid, @metadata_type33 as metadata_type, @lineage_old33 as lineage_old, @lineage_new33 as lineage_new, @generation33 as generation  union all 
    select @rowguid34 as rowguid, @metadata_type34 as metadata_type, @lineage_old34 as lineage_old, @lineage_new34 as lineage_new, @generation34 as generation  union all 
    select @rowguid35 as rowguid, @metadata_type35 as metadata_type, @lineage_old35 as lineage_old, @lineage_new35 as lineage_new, @generation35 as generation  union all 
    select @rowguid36 as rowguid, @metadata_type36 as metadata_type, @lineage_old36 as lineage_old, @lineage_new36 as lineage_new, @generation36 as generation  union all 
    select @rowguid37 as rowguid, @metadata_type37 as metadata_type, @lineage_old37 as lineage_old, @lineage_new37 as lineage_new, @generation37 as generation  union all 
    select @rowguid38 as rowguid, @metadata_type38 as metadata_type, @lineage_old38 as lineage_old, @lineage_new38 as lineage_new, @generation38 as generation  union all 
    select @rowguid39 as rowguid, @metadata_type39 as metadata_type, @lineage_old39 as lineage_old, @lineage_new39 as lineage_new, @generation39 as generation  union all 
    select @rowguid40 as rowguid, @metadata_type40 as metadata_type, @lineage_old40 as lineage_old, @lineage_new40 as lineage_new, @generation40 as generation 
 union all 
    select @rowguid41 as rowguid, @metadata_type41 as metadata_type, @lineage_old41 as lineage_old, @lineage_new41 as lineage_new, @generation41 as generation  union all 
    select @rowguid42 as rowguid, @metadata_type42 as metadata_type, @lineage_old42 as lineage_old, @lineage_new42 as lineage_new, @generation42 as generation  union all 
    select @rowguid43 as rowguid, @metadata_type43 as metadata_type, @lineage_old43 as lineage_old, @lineage_new43 as lineage_new, @generation43 as generation  union all 
    select @rowguid44 as rowguid, @metadata_type44 as metadata_type, @lineage_old44 as lineage_old, @lineage_new44 as lineage_new, @generation44 as generation  union all 
    select @rowguid45 as rowguid, @metadata_type45 as metadata_type, @lineage_old45 as lineage_old, @lineage_new45 as lineage_new, @generation45 as generation  union all 
    select @rowguid46 as rowguid, @metadata_type46 as metadata_type, @lineage_old46 as lineage_old, @lineage_new46 as lineage_new, @generation46 as generation  union all 
    select @rowguid47 as rowguid, @metadata_type47 as metadata_type, @lineage_old47 as lineage_old, @lineage_new47 as lineage_new, @generation47 as generation  union all 
    select @rowguid48 as rowguid, @metadata_type48 as metadata_type, @lineage_old48 as lineage_old, @lineage_new48 as lineage_new, @generation48 as generation  union all 
    select @rowguid49 as rowguid, @metadata_type49 as metadata_type, @lineage_old49 as lineage_old, @lineage_new49 as lineage_new, @generation49 as generation  union all 
    select @rowguid50 as rowguid, @metadata_type50 as metadata_type, @lineage_old50 as lineage_old, @lineage_new50 as lineage_new, @generation50 as generation 
 union all 
    select @rowguid51 as rowguid, @metadata_type51 as metadata_type, @lineage_old51 as lineage_old, @lineage_new51 as lineage_new, @generation51 as generation  union all 
    select @rowguid52 as rowguid, @metadata_type52 as metadata_type, @lineage_old52 as lineage_old, @lineage_new52 as lineage_new, @generation52 as generation  union all 
    select @rowguid53 as rowguid, @metadata_type53 as metadata_type, @lineage_old53 as lineage_old, @lineage_new53 as lineage_new, @generation53 as generation  union all 
    select @rowguid54 as rowguid, @metadata_type54 as metadata_type, @lineage_old54 as lineage_old, @lineage_new54 as lineage_new, @generation54 as generation  union all 
    select @rowguid55 as rowguid, @metadata_type55 as metadata_type, @lineage_old55 as lineage_old, @lineage_new55 as lineage_new, @generation55 as generation  union all 
    select @rowguid56 as rowguid, @metadata_type56 as metadata_type, @lineage_old56 as lineage_old, @lineage_new56 as lineage_new, @generation56 as generation  union all 
    select @rowguid57 as rowguid, @metadata_type57 as metadata_type, @lineage_old57 as lineage_old, @lineage_new57 as lineage_new, @generation57 as generation  union all 
    select @rowguid58 as rowguid, @metadata_type58 as metadata_type, @lineage_old58 as lineage_old, @lineage_new58 as lineage_new, @generation58 as generation  union all 
    select @rowguid59 as rowguid, @metadata_type59 as metadata_type, @lineage_old59 as lineage_old, @lineage_new59 as lineage_new, @generation59 as generation  union all 
    select @rowguid60 as rowguid, @metadata_type60 as metadata_type, @lineage_old60 as lineage_old, @lineage_new60 as lineage_new, @generation60 as generation 
 union all 
    select @rowguid61 as rowguid, @metadata_type61 as metadata_type, @lineage_old61 as lineage_old, @lineage_new61 as lineage_new, @generation61 as generation  union all 
    select @rowguid62 as rowguid, @metadata_type62 as metadata_type, @lineage_old62 as lineage_old, @lineage_new62 as lineage_new, @generation62 as generation  union all 
    select @rowguid63 as rowguid, @metadata_type63 as metadata_type, @lineage_old63 as lineage_old, @lineage_new63 as lineage_new, @generation63 as generation  union all 
    select @rowguid64 as rowguid, @metadata_type64 as metadata_type, @lineage_old64 as lineage_old, @lineage_new64 as lineage_new, @generation64 as generation  union all 
    select @rowguid65 as rowguid, @metadata_type65 as metadata_type, @lineage_old65 as lineage_old, @lineage_new65 as lineage_new, @generation65 as generation  union all 
    select @rowguid66 as rowguid, @metadata_type66 as metadata_type, @lineage_old66 as lineage_old, @lineage_new66 as lineage_new, @generation66 as generation  union all 
    select @rowguid67 as rowguid, @metadata_type67 as metadata_type, @lineage_old67 as lineage_old, @lineage_new67 as lineage_new, @generation67 as generation  union all 
    select @rowguid68 as rowguid, @metadata_type68 as metadata_type, @lineage_old68 as lineage_old, @lineage_new68 as lineage_new, @generation68 as generation  union all 
    select @rowguid69 as rowguid, @metadata_type69 as metadata_type, @lineage_old69 as lineage_old, @lineage_new69 as lineage_new, @generation69 as generation  union all 
    select @rowguid70 as rowguid, @metadata_type70 as metadata_type, @lineage_old70 as lineage_old, @lineage_new70 as lineage_new, @generation70 as generation 
 union all 
    select @rowguid71 as rowguid, @metadata_type71 as metadata_type, @lineage_old71 as lineage_old, @lineage_new71 as lineage_new, @generation71 as generation  union all 
    select @rowguid72 as rowguid, @metadata_type72 as metadata_type, @lineage_old72 as lineage_old, @lineage_new72 as lineage_new, @generation72 as generation  union all 
    select @rowguid73 as rowguid, @metadata_type73 as metadata_type, @lineage_old73 as lineage_old, @lineage_new73 as lineage_new, @generation73 as generation  union all 
    select @rowguid74 as rowguid, @metadata_type74 as metadata_type, @lineage_old74 as lineage_old, @lineage_new74 as lineage_new, @generation74 as generation  union all 
    select @rowguid75 as rowguid, @metadata_type75 as metadata_type, @lineage_old75 as lineage_old, @lineage_new75 as lineage_new, @generation75 as generation  union all 
    select @rowguid76 as rowguid, @metadata_type76 as metadata_type, @lineage_old76 as lineage_old, @lineage_new76 as lineage_new, @generation76 as generation  union all 
    select @rowguid77 as rowguid, @metadata_type77 as metadata_type, @lineage_old77 as lineage_old, @lineage_new77 as lineage_new, @generation77 as generation  union all 
    select @rowguid78 as rowguid, @metadata_type78 as metadata_type, @lineage_old78 as lineage_old, @lineage_new78 as lineage_new, @generation78 as generation  union all 
    select @rowguid79 as rowguid, @metadata_type79 as metadata_type, @lineage_old79 as lineage_old, @lineage_new79 as lineage_new, @generation79 as generation  union all 
    select @rowguid80 as rowguid, @metadata_type80 as metadata_type, @lineage_old80 as lineage_old, @lineage_new80 as lineage_new, @generation80 as generation 
 union all 
    select @rowguid81 as rowguid, @metadata_type81 as metadata_type, @lineage_old81 as lineage_old, @lineage_new81 as lineage_new, @generation81 as generation  union all 
    select @rowguid82 as rowguid, @metadata_type82 as metadata_type, @lineage_old82 as lineage_old, @lineage_new82 as lineage_new, @generation82 as generation  union all 
    select @rowguid83 as rowguid, @metadata_type83 as metadata_type, @lineage_old83 as lineage_old, @lineage_new83 as lineage_new, @generation83 as generation  union all 
    select @rowguid84 as rowguid, @metadata_type84 as metadata_type, @lineage_old84 as lineage_old, @lineage_new84 as lineage_new, @generation84 as generation  union all 
    select @rowguid85 as rowguid, @metadata_type85 as metadata_type, @lineage_old85 as lineage_old, @lineage_new85 as lineage_new, @generation85 as generation  union all 
    select @rowguid86 as rowguid, @metadata_type86 as metadata_type, @lineage_old86 as lineage_old, @lineage_new86 as lineage_new, @generation86 as generation  union all 
    select @rowguid87 as rowguid, @metadata_type87 as metadata_type, @lineage_old87 as lineage_old, @lineage_new87 as lineage_new, @generation87 as generation  union all 
    select @rowguid88 as rowguid, @metadata_type88 as metadata_type, @lineage_old88 as lineage_old, @lineage_new88 as lineage_new, @generation88 as generation  union all 
    select @rowguid89 as rowguid, @metadata_type89 as metadata_type, @lineage_old89 as lineage_old, @lineage_new89 as lineage_new, @generation89 as generation  union all 
    select @rowguid90 as rowguid, @metadata_type90 as metadata_type, @lineage_old90 as lineage_old, @lineage_new90 as lineage_new, @generation90 as generation 
 union all 
    select @rowguid91 as rowguid, @metadata_type91 as metadata_type, @lineage_old91 as lineage_old, @lineage_new91 as lineage_new, @generation91 as generation  union all 
    select @rowguid92 as rowguid, @metadata_type92 as metadata_type, @lineage_old92 as lineage_old, @lineage_new92 as lineage_new, @generation92 as generation  union all 
    select @rowguid93 as rowguid, @metadata_type93 as metadata_type, @lineage_old93 as lineage_old, @lineage_new93 as lineage_new, @generation93 as generation  union all 
    select @rowguid94 as rowguid, @metadata_type94 as metadata_type, @lineage_old94 as lineage_old, @lineage_new94 as lineage_new, @generation94 as generation  union all 
    select @rowguid95 as rowguid, @metadata_type95 as metadata_type, @lineage_old95 as lineage_old, @lineage_new95 as lineage_new, @generation95 as generation  union all 
    select @rowguid96 as rowguid, @metadata_type96 as metadata_type, @lineage_old96 as lineage_old, @lineage_new96 as lineage_new, @generation96 as generation  union all 
    select @rowguid97 as rowguid, @metadata_type97 as metadata_type, @lineage_old97 as lineage_old, @lineage_new97 as lineage_new, @generation97 as generation  union all 
    select @rowguid98 as rowguid, @metadata_type98 as metadata_type, @lineage_old98 as lineage_old, @lineage_new98 as lineage_new, @generation98 as generation  union all 
    select @rowguid99 as rowguid, @metadata_type99 as metadata_type, @lineage_old99 as lineage_old, @lineage_new99 as lineage_new, @generation99 as generation  union all 
    select @rowguid100 as rowguid, @metadata_type100 as metadata_type, @lineage_old100 as lineage_old, @lineage_new100 as lineage_new, @generation100 as generation 
) as rows
    inner join [dbo].[SANPHAM] t with (rowlock) on rows.rowguid = t.[rowguid] and rows.rowguid is not NULL

    left outer join dbo.MSmerge_contents cont with (rowlock) 
    on rows.rowguid = cont.rowguid and cont.tablenick = 49871000 
    and rows.rowguid is not NULL
    where ((rows.metadata_type = 3 and cont.rowguid is NULL) or
           ((rows.metadata_type = 5 or  rows.metadata_type = 6) and (cont.rowguid is NULL or cont.lineage = rows.lineage_old)) or
           (cont.rowguid is not NULL and cont.lineage = rows.lineage_old))
           and rows.rowguid is not NULL 

    select @rows_deleted = @@rowcount, @error = @@error
    if @error<>0
        goto Failure
    if @rows_deleted > @rowstobedeleted
    begin
        -- this is just not possible
        raiserror(20684, 16, -1, '[dbo].[SANPHAM]')
        goto Failure
    end
    if @rows_deleted <> @rowstobedeleted
    begin

        -- we will now check if any of the rows we wanted to delete were not deleted. If the rows were not deleted
        -- by the previous delete because it was already deleted, we will still assume that this is a success
        select @rows_remaining = count(*) from 
        ( 

         select @rowguid1 as rowguid union all 
         select @rowguid2 as rowguid union all 
         select @rowguid3 as rowguid union all 
         select @rowguid4 as rowguid union all 
         select @rowguid5 as rowguid union all 
         select @rowguid6 as rowguid union all 
         select @rowguid7 as rowguid union all 
         select @rowguid8 as rowguid union all 
         select @rowguid9 as rowguid union all 
         select @rowguid10 as rowguid union all 
         select @rowguid11 as rowguid union all 
         select @rowguid12 as rowguid union all 
         select @rowguid13 as rowguid union all 
         select @rowguid14 as rowguid union all 
         select @rowguid15 as rowguid union all 
         select @rowguid16 as rowguid union all 
         select @rowguid17 as rowguid union all 
         select @rowguid18 as rowguid union all 
         select @rowguid19 as rowguid union all 
         select @rowguid20 as rowguid union all 
         select @rowguid21 as rowguid union all 
         select @rowguid22 as rowguid union all 
         select @rowguid23 as rowguid union all 
         select @rowguid24 as rowguid union all 
         select @rowguid25 as rowguid union all 
         select @rowguid26 as rowguid union all 
         select @rowguid27 as rowguid union all 
         select @rowguid28 as rowguid union all 
         select @rowguid29 as rowguid union all 
         select @rowguid30 as rowguid union all 
         select @rowguid31 as rowguid union all 
         select @rowguid32 as rowguid union all 
         select @rowguid33 as rowguid union all 
         select @rowguid34 as rowguid union all 
         select @rowguid35 as rowguid union all 
         select @rowguid36 as rowguid union all 
         select @rowguid37 as rowguid union all 
         select @rowguid38 as rowguid union all 
         select @rowguid39 as rowguid union all 
         select @rowguid40 as rowguid union all 
         select @rowguid41 as rowguid union all 
         select @rowguid42 as rowguid union all 
         select @rowguid43 as rowguid union all 
         select @rowguid44 as rowguid union all 
         select @rowguid45 as rowguid union all 
         select @rowguid46 as rowguid union all 
         select @rowguid47 as rowguid union all 
         select @rowguid48 as rowguid union all 
         select @rowguid49 as rowguid union all 
         select @rowguid50 as rowguid union all

         select @rowguid51 as rowguid union all 
         select @rowguid52 as rowguid union all 
         select @rowguid53 as rowguid union all 
         select @rowguid54 as rowguid union all 
         select @rowguid55 as rowguid union all 
         select @rowguid56 as rowguid union all 
         select @rowguid57 as rowguid union all 
         select @rowguid58 as rowguid union all 
         select @rowguid59 as rowguid union all 
         select @rowguid60 as rowguid union all 
         select @rowguid61 as rowguid union all 
         select @rowguid62 as rowguid union all 
         select @rowguid63 as rowguid union all 
         select @rowguid64 as rowguid union all 
         select @rowguid65 as rowguid union all 
         select @rowguid66 as rowguid union all 
         select @rowguid67 as rowguid union all 
         select @rowguid68 as rowguid union all 
         select @rowguid69 as rowguid union all 
         select @rowguid70 as rowguid union all 
         select @rowguid71 as rowguid union all 
         select @rowguid72 as rowguid union all 
         select @rowguid73 as rowguid union all 
         select @rowguid74 as rowguid union all 
         select @rowguid75 as rowguid union all 
         select @rowguid76 as rowguid union all 
         select @rowguid77 as rowguid union all 
         select @rowguid78 as rowguid union all 
         select @rowguid79 as rowguid union all 
         select @rowguid80 as rowguid union all 
         select @rowguid81 as rowguid union all 
         select @rowguid82 as rowguid union all 
         select @rowguid83 as rowguid union all 
         select @rowguid84 as rowguid union all 
         select @rowguid85 as rowguid union all 
         select @rowguid86 as rowguid union all 
         select @rowguid87 as rowguid union all 
         select @rowguid88 as rowguid union all 
         select @rowguid89 as rowguid union all 
         select @rowguid90 as rowguid union all 
         select @rowguid91 as rowguid union all 
         select @rowguid92 as rowguid union all 
         select @rowguid93 as rowguid union all 
         select @rowguid94 as rowguid union all 
         select @rowguid95 as rowguid union all 
         select @rowguid96 as rowguid union all 
         select @rowguid97 as rowguid union all 
         select @rowguid98 as rowguid union all 
         select @rowguid99 as rowguid union all 
         select @rowguid100 as rowguid

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid
        and rows.rowguid is not NULL
        
        if @@error <> 0
            goto Failure
        
        if @rows_remaining <> 0
        begin
            -- failed deleting one or more rows. Could be because of metadata mismatch
            --raiserror(20682, 10, -1, @rows_remaining, '[dbo].[SANPHAM]')
            goto Failure
        end        
    end

    -- if we get here it means that all the rows that we intend to delete were either deleted by us
    -- or they were already deleted by someone else and do not exist in the user table
    -- we insert a tombstone entry for the rows we have deleted and delete the contents rows if exists

    -- if the rows were previously deleted we still want to update the metadatatype, generation and lineage
    -- in MSmerge_tombstone. We could find rows in the following update also if the trigger got called by
    -- the user table delete and it inserted the rows into tombstone (it would have inserted with type 1)
    update dbo.MSmerge_tombstone with (rowlock)
        set type = case when (rows.metadata_type=5 or rows.metadata_type=6) then rows.metadata_type else 1 end,
            generation = rows.generation,
            lineage = rows.lineage_new
    from 
    (

    select @rowguid1 as rowguid, @metadata_type1 as metadata_type, @lineage_old1 as lineage_old, @lineage_new1 as lineage_new, @generation1 as generation  union all 
    select @rowguid2 as rowguid, @metadata_type2 as metadata_type, @lineage_old2 as lineage_old, @lineage_new2 as lineage_new, @generation2 as generation  union all 
    select @rowguid3 as rowguid, @metadata_type3 as metadata_type, @lineage_old3 as lineage_old, @lineage_new3 as lineage_new, @generation3 as generation  union all 
    select @rowguid4 as rowguid, @metadata_type4 as metadata_type, @lineage_old4 as lineage_old, @lineage_new4 as lineage_new, @generation4 as generation  union all 
    select @rowguid5 as rowguid, @metadata_type5 as metadata_type, @lineage_old5 as lineage_old, @lineage_new5 as lineage_new, @generation5 as generation  union all 
    select @rowguid6 as rowguid, @metadata_type6 as metadata_type, @lineage_old6 as lineage_old, @lineage_new6 as lineage_new, @generation6 as generation  union all 
    select @rowguid7 as rowguid, @metadata_type7 as metadata_type, @lineage_old7 as lineage_old, @lineage_new7 as lineage_new, @generation7 as generation  union all 
    select @rowguid8 as rowguid, @metadata_type8 as metadata_type, @lineage_old8 as lineage_old, @lineage_new8 as lineage_new, @generation8 as generation  union all 
    select @rowguid9 as rowguid, @metadata_type9 as metadata_type, @lineage_old9 as lineage_old, @lineage_new9 as lineage_new, @generation9 as generation  union all 
    select @rowguid10 as rowguid, @metadata_type10 as metadata_type, @lineage_old10 as lineage_old, @lineage_new10 as lineage_new, @generation10 as generation 
 union all 
    select @rowguid11 as rowguid, @metadata_type11 as metadata_type, @lineage_old11 as lineage_old, @lineage_new11 as lineage_new, @generation11 as generation  union all 
    select @rowguid12 as rowguid, @metadata_type12 as metadata_type, @lineage_old12 as lineage_old, @lineage_new12 as lineage_new, @generation12 as generation  union all 
    select @rowguid13 as rowguid, @metadata_type13 as metadata_type, @lineage_old13 as lineage_old, @lineage_new13 as lineage_new, @generation13 as generation  union all 
    select @rowguid14 as rowguid, @metadata_type14 as metadata_type, @lineage_old14 as lineage_old, @lineage_new14 as lineage_new, @generation14 as generation  union all 
    select @rowguid15 as rowguid, @metadata_type15 as metadata_type, @lineage_old15 as lineage_old, @lineage_new15 as lineage_new, @generation15 as generation  union all 
    select @rowguid16 as rowguid, @metadata_type16 as metadata_type, @lineage_old16 as lineage_old, @lineage_new16 as lineage_new, @generation16 as generation  union all 
    select @rowguid17 as rowguid, @metadata_type17 as metadata_type, @lineage_old17 as lineage_old, @lineage_new17 as lineage_new, @generation17 as generation  union all 
    select @rowguid18 as rowguid, @metadata_type18 as metadata_type, @lineage_old18 as lineage_old, @lineage_new18 as lineage_new, @generation18 as generation  union all 
    select @rowguid19 as rowguid, @metadata_type19 as metadata_type, @lineage_old19 as lineage_old, @lineage_new19 as lineage_new, @generation19 as generation  union all 
    select @rowguid20 as rowguid, @metadata_type20 as metadata_type, @lineage_old20 as lineage_old, @lineage_new20 as lineage_new, @generation20 as generation 
 union all 
    select @rowguid21 as rowguid, @metadata_type21 as metadata_type, @lineage_old21 as lineage_old, @lineage_new21 as lineage_new, @generation21 as generation  union all 
    select @rowguid22 as rowguid, @metadata_type22 as metadata_type, @lineage_old22 as lineage_old, @lineage_new22 as lineage_new, @generation22 as generation  union all 
    select @rowguid23 as rowguid, @metadata_type23 as metadata_type, @lineage_old23 as lineage_old, @lineage_new23 as lineage_new, @generation23 as generation  union all 
    select @rowguid24 as rowguid, @metadata_type24 as metadata_type, @lineage_old24 as lineage_old, @lineage_new24 as lineage_new, @generation24 as generation  union all 
    select @rowguid25 as rowguid, @metadata_type25 as metadata_type, @lineage_old25 as lineage_old, @lineage_new25 as lineage_new, @generation25 as generation  union all 
    select @rowguid26 as rowguid, @metadata_type26 as metadata_type, @lineage_old26 as lineage_old, @lineage_new26 as lineage_new, @generation26 as generation  union all 
    select @rowguid27 as rowguid, @metadata_type27 as metadata_type, @lineage_old27 as lineage_old, @lineage_new27 as lineage_new, @generation27 as generation  union all 
    select @rowguid28 as rowguid, @metadata_type28 as metadata_type, @lineage_old28 as lineage_old, @lineage_new28 as lineage_new, @generation28 as generation  union all 
    select @rowguid29 as rowguid, @metadata_type29 as metadata_type, @lineage_old29 as lineage_old, @lineage_new29 as lineage_new, @generation29 as generation  union all 
    select @rowguid30 as rowguid, @metadata_type30 as metadata_type, @lineage_old30 as lineage_old, @lineage_new30 as lineage_new, @generation30 as generation 
 union all 
    select @rowguid31 as rowguid, @metadata_type31 as metadata_type, @lineage_old31 as lineage_old, @lineage_new31 as lineage_new, @generation31 as generation  union all 
    select @rowguid32 as rowguid, @metadata_type32 as metadata_type, @lineage_old32 as lineage_old, @lineage_new32 as lineage_new, @generation32 as generation  union all 
    select @rowguid33 as rowguid, @metadata_type33 as metadata_type, @lineage_old33 as lineage_old, @lineage_new33 as lineage_new, @generation33 as generation  union all 
    select @rowguid34 as rowguid, @metadata_type34 as metadata_type, @lineage_old34 as lineage_old, @lineage_new34 as lineage_new, @generation34 as generation  union all 
    select @rowguid35 as rowguid, @metadata_type35 as metadata_type, @lineage_old35 as lineage_old, @lineage_new35 as lineage_new, @generation35 as generation  union all 
    select @rowguid36 as rowguid, @metadata_type36 as metadata_type, @lineage_old36 as lineage_old, @lineage_new36 as lineage_new, @generation36 as generation  union all 
    select @rowguid37 as rowguid, @metadata_type37 as metadata_type, @lineage_old37 as lineage_old, @lineage_new37 as lineage_new, @generation37 as generation  union all 
    select @rowguid38 as rowguid, @metadata_type38 as metadata_type, @lineage_old38 as lineage_old, @lineage_new38 as lineage_new, @generation38 as generation  union all 
    select @rowguid39 as rowguid, @metadata_type39 as metadata_type, @lineage_old39 as lineage_old, @lineage_new39 as lineage_new, @generation39 as generation  union all 
    select @rowguid40 as rowguid, @metadata_type40 as metadata_type, @lineage_old40 as lineage_old, @lineage_new40 as lineage_new, @generation40 as generation 
 union all 
    select @rowguid41 as rowguid, @metadata_type41 as metadata_type, @lineage_old41 as lineage_old, @lineage_new41 as lineage_new, @generation41 as generation  union all 
    select @rowguid42 as rowguid, @metadata_type42 as metadata_type, @lineage_old42 as lineage_old, @lineage_new42 as lineage_new, @generation42 as generation  union all 
    select @rowguid43 as rowguid, @metadata_type43 as metadata_type, @lineage_old43 as lineage_old, @lineage_new43 as lineage_new, @generation43 as generation  union all 
    select @rowguid44 as rowguid, @metadata_type44 as metadata_type, @lineage_old44 as lineage_old, @lineage_new44 as lineage_new, @generation44 as generation  union all 
    select @rowguid45 as rowguid, @metadata_type45 as metadata_type, @lineage_old45 as lineage_old, @lineage_new45 as lineage_new, @generation45 as generation  union all 
    select @rowguid46 as rowguid, @metadata_type46 as metadata_type, @lineage_old46 as lineage_old, @lineage_new46 as lineage_new, @generation46 as generation  union all 
    select @rowguid47 as rowguid, @metadata_type47 as metadata_type, @lineage_old47 as lineage_old, @lineage_new47 as lineage_new, @generation47 as generation  union all 
    select @rowguid48 as rowguid, @metadata_type48 as metadata_type, @lineage_old48 as lineage_old, @lineage_new48 as lineage_new, @generation48 as generation  union all 
    select @rowguid49 as rowguid, @metadata_type49 as metadata_type, @lineage_old49 as lineage_old, @lineage_new49 as lineage_new, @generation49 as generation  union all 
    select @rowguid50 as rowguid, @metadata_type50 as metadata_type, @lineage_old50 as lineage_old, @lineage_new50 as lineage_new, @generation50 as generation 
 union all 
    select @rowguid51 as rowguid, @metadata_type51 as metadata_type, @lineage_old51 as lineage_old, @lineage_new51 as lineage_new, @generation51 as generation  union all 
    select @rowguid52 as rowguid, @metadata_type52 as metadata_type, @lineage_old52 as lineage_old, @lineage_new52 as lineage_new, @generation52 as generation  union all 
    select @rowguid53 as rowguid, @metadata_type53 as metadata_type, @lineage_old53 as lineage_old, @lineage_new53 as lineage_new, @generation53 as generation  union all 
    select @rowguid54 as rowguid, @metadata_type54 as metadata_type, @lineage_old54 as lineage_old, @lineage_new54 as lineage_new, @generation54 as generation  union all 
    select @rowguid55 as rowguid, @metadata_type55 as metadata_type, @lineage_old55 as lineage_old, @lineage_new55 as lineage_new, @generation55 as generation  union all 
    select @rowguid56 as rowguid, @metadata_type56 as metadata_type, @lineage_old56 as lineage_old, @lineage_new56 as lineage_new, @generation56 as generation  union all 
    select @rowguid57 as rowguid, @metadata_type57 as metadata_type, @lineage_old57 as lineage_old, @lineage_new57 as lineage_new, @generation57 as generation  union all 
    select @rowguid58 as rowguid, @metadata_type58 as metadata_type, @lineage_old58 as lineage_old, @lineage_new58 as lineage_new, @generation58 as generation  union all 
    select @rowguid59 as rowguid, @metadata_type59 as metadata_type, @lineage_old59 as lineage_old, @lineage_new59 as lineage_new, @generation59 as generation  union all 
    select @rowguid60 as rowguid, @metadata_type60 as metadata_type, @lineage_old60 as lineage_old, @lineage_new60 as lineage_new, @generation60 as generation 
 union all 
    select @rowguid61 as rowguid, @metadata_type61 as metadata_type, @lineage_old61 as lineage_old, @lineage_new61 as lineage_new, @generation61 as generation  union all 
    select @rowguid62 as rowguid, @metadata_type62 as metadata_type, @lineage_old62 as lineage_old, @lineage_new62 as lineage_new, @generation62 as generation  union all 
    select @rowguid63 as rowguid, @metadata_type63 as metadata_type, @lineage_old63 as lineage_old, @lineage_new63 as lineage_new, @generation63 as generation  union all 
    select @rowguid64 as rowguid, @metadata_type64 as metadata_type, @lineage_old64 as lineage_old, @lineage_new64 as lineage_new, @generation64 as generation  union all 
    select @rowguid65 as rowguid, @metadata_type65 as metadata_type, @lineage_old65 as lineage_old, @lineage_new65 as lineage_new, @generation65 as generation  union all 
    select @rowguid66 as rowguid, @metadata_type66 as metadata_type, @lineage_old66 as lineage_old, @lineage_new66 as lineage_new, @generation66 as generation  union all 
    select @rowguid67 as rowguid, @metadata_type67 as metadata_type, @lineage_old67 as lineage_old, @lineage_new67 as lineage_new, @generation67 as generation  union all 
    select @rowguid68 as rowguid, @metadata_type68 as metadata_type, @lineage_old68 as lineage_old, @lineage_new68 as lineage_new, @generation68 as generation  union all 
    select @rowguid69 as rowguid, @metadata_type69 as metadata_type, @lineage_old69 as lineage_old, @lineage_new69 as lineage_new, @generation69 as generation  union all 
    select @rowguid70 as rowguid, @metadata_type70 as metadata_type, @lineage_old70 as lineage_old, @lineage_new70 as lineage_new, @generation70 as generation 
 union all 
    select @rowguid71 as rowguid, @metadata_type71 as metadata_type, @lineage_old71 as lineage_old, @lineage_new71 as lineage_new, @generation71 as generation  union all 
    select @rowguid72 as rowguid, @metadata_type72 as metadata_type, @lineage_old72 as lineage_old, @lineage_new72 as lineage_new, @generation72 as generation  union all 
    select @rowguid73 as rowguid, @metadata_type73 as metadata_type, @lineage_old73 as lineage_old, @lineage_new73 as lineage_new, @generation73 as generation  union all 
    select @rowguid74 as rowguid, @metadata_type74 as metadata_type, @lineage_old74 as lineage_old, @lineage_new74 as lineage_new, @generation74 as generation  union all 
    select @rowguid75 as rowguid, @metadata_type75 as metadata_type, @lineage_old75 as lineage_old, @lineage_new75 as lineage_new, @generation75 as generation  union all 
    select @rowguid76 as rowguid, @metadata_type76 as metadata_type, @lineage_old76 as lineage_old, @lineage_new76 as lineage_new, @generation76 as generation  union all 
    select @rowguid77 as rowguid, @metadata_type77 as metadata_type, @lineage_old77 as lineage_old, @lineage_new77 as lineage_new, @generation77 as generation  union all 
    select @rowguid78 as rowguid, @metadata_type78 as metadata_type, @lineage_old78 as lineage_old, @lineage_new78 as lineage_new, @generation78 as generation  union all 
    select @rowguid79 as rowguid, @metadata_type79 as metadata_type, @lineage_old79 as lineage_old, @lineage_new79 as lineage_new, @generation79 as generation  union all 
    select @rowguid80 as rowguid, @metadata_type80 as metadata_type, @lineage_old80 as lineage_old, @lineage_new80 as lineage_new, @generation80 as generation 
 union all 
    select @rowguid81 as rowguid, @metadata_type81 as metadata_type, @lineage_old81 as lineage_old, @lineage_new81 as lineage_new, @generation81 as generation  union all 
    select @rowguid82 as rowguid, @metadata_type82 as metadata_type, @lineage_old82 as lineage_old, @lineage_new82 as lineage_new, @generation82 as generation  union all 
    select @rowguid83 as rowguid, @metadata_type83 as metadata_type, @lineage_old83 as lineage_old, @lineage_new83 as lineage_new, @generation83 as generation  union all 
    select @rowguid84 as rowguid, @metadata_type84 as metadata_type, @lineage_old84 as lineage_old, @lineage_new84 as lineage_new, @generation84 as generation  union all 
    select @rowguid85 as rowguid, @metadata_type85 as metadata_type, @lineage_old85 as lineage_old, @lineage_new85 as lineage_new, @generation85 as generation  union all 
    select @rowguid86 as rowguid, @metadata_type86 as metadata_type, @lineage_old86 as lineage_old, @lineage_new86 as lineage_new, @generation86 as generation  union all 
    select @rowguid87 as rowguid, @metadata_type87 as metadata_type, @lineage_old87 as lineage_old, @lineage_new87 as lineage_new, @generation87 as generation  union all 
    select @rowguid88 as rowguid, @metadata_type88 as metadata_type, @lineage_old88 as lineage_old, @lineage_new88 as lineage_new, @generation88 as generation  union all 
    select @rowguid89 as rowguid, @metadata_type89 as metadata_type, @lineage_old89 as lineage_old, @lineage_new89 as lineage_new, @generation89 as generation  union all 
    select @rowguid90 as rowguid, @metadata_type90 as metadata_type, @lineage_old90 as lineage_old, @lineage_new90 as lineage_new, @generation90 as generation 
 union all 
    select @rowguid91 as rowguid, @metadata_type91 as metadata_type, @lineage_old91 as lineage_old, @lineage_new91 as lineage_new, @generation91 as generation  union all 
    select @rowguid92 as rowguid, @metadata_type92 as metadata_type, @lineage_old92 as lineage_old, @lineage_new92 as lineage_new, @generation92 as generation  union all 
    select @rowguid93 as rowguid, @metadata_type93 as metadata_type, @lineage_old93 as lineage_old, @lineage_new93 as lineage_new, @generation93 as generation  union all 
    select @rowguid94 as rowguid, @metadata_type94 as metadata_type, @lineage_old94 as lineage_old, @lineage_new94 as lineage_new, @generation94 as generation  union all 
    select @rowguid95 as rowguid, @metadata_type95 as metadata_type, @lineage_old95 as lineage_old, @lineage_new95 as lineage_new, @generation95 as generation  union all 
    select @rowguid96 as rowguid, @metadata_type96 as metadata_type, @lineage_old96 as lineage_old, @lineage_new96 as lineage_new, @generation96 as generation  union all 
    select @rowguid97 as rowguid, @metadata_type97 as metadata_type, @lineage_old97 as lineage_old, @lineage_new97 as lineage_new, @generation97 as generation  union all 
    select @rowguid98 as rowguid, @metadata_type98 as metadata_type, @lineage_old98 as lineage_old, @lineage_new98 as lineage_new, @generation98 as generation  union all 
    select @rowguid99 as rowguid, @metadata_type99 as metadata_type, @lineage_old99 as lineage_old, @lineage_new99 as lineage_new, @generation99 as generation  union all 
    select @rowguid100 as rowguid, @metadata_type100 as metadata_type, @lineage_old100 as lineage_old, @lineage_new100 as lineage_new, @generation100 as generation 

    ) as rows
    inner join dbo.MSmerge_tombstone tomb with (rowlock) 
    on tomb.rowguid = rows.rowguid and tomb.tablenick = 49871000
    and rows.rowguid is not null
    and rows.lineage_new is not NULL
    option (force order, loop join)
    select @tomb_rows_updated = @@rowcount, @error = @@error
    if @error<>0
        goto Failure

        -- the trigger would have inserted a row in past partition mapping for the currently deleted
        -- row. We need to update that row with the current generation if it exists
        update dbo.MSmerge_past_partition_mappings with (rowlock)
        set generation = rows.generation
    from
    (

    select @rowguid1 as rowguid, @metadata_type1 as metadata_type, @lineage_old1 as lineage_old, @lineage_new1 as lineage_new, @generation1 as generation  union all 
    select @rowguid2 as rowguid, @metadata_type2 as metadata_type, @lineage_old2 as lineage_old, @lineage_new2 as lineage_new, @generation2 as generation  union all 
    select @rowguid3 as rowguid, @metadata_type3 as metadata_type, @lineage_old3 as lineage_old, @lineage_new3 as lineage_new, @generation3 as generation  union all 
    select @rowguid4 as rowguid, @metadata_type4 as metadata_type, @lineage_old4 as lineage_old, @lineage_new4 as lineage_new, @generation4 as generation  union all 
    select @rowguid5 as rowguid, @metadata_type5 as metadata_type, @lineage_old5 as lineage_old, @lineage_new5 as lineage_new, @generation5 as generation  union all 
    select @rowguid6 as rowguid, @metadata_type6 as metadata_type, @lineage_old6 as lineage_old, @lineage_new6 as lineage_new, @generation6 as generation  union all 
    select @rowguid7 as rowguid, @metadata_type7 as metadata_type, @lineage_old7 as lineage_old, @lineage_new7 as lineage_new, @generation7 as generation  union all 
    select @rowguid8 as rowguid, @metadata_type8 as metadata_type, @lineage_old8 as lineage_old, @lineage_new8 as lineage_new, @generation8 as generation  union all 
    select @rowguid9 as rowguid, @metadata_type9 as metadata_type, @lineage_old9 as lineage_old, @lineage_new9 as lineage_new, @generation9 as generation  union all 
    select @rowguid10 as rowguid, @metadata_type10 as metadata_type, @lineage_old10 as lineage_old, @lineage_new10 as lineage_new, @generation10 as generation 
 union all 
    select @rowguid11 as rowguid, @metadata_type11 as metadata_type, @lineage_old11 as lineage_old, @lineage_new11 as lineage_new, @generation11 as generation  union all 
    select @rowguid12 as rowguid, @metadata_type12 as metadata_type, @lineage_old12 as lineage_old, @lineage_new12 as lineage_new, @generation12 as generation  union all 
    select @rowguid13 as rowguid, @metadata_type13 as metadata_type, @lineage_old13 as lineage_old, @lineage_new13 as lineage_new, @generation13 as generation  union all 
    select @rowguid14 as rowguid, @metadata_type14 as metadata_type, @lineage_old14 as lineage_old, @lineage_new14 as lineage_new, @generation14 as generation  union all 
    select @rowguid15 as rowguid, @metadata_type15 as metadata_type, @lineage_old15 as lineage_old, @lineage_new15 as lineage_new, @generation15 as generation  union all 
    select @rowguid16 as rowguid, @metadata_type16 as metadata_type, @lineage_old16 as lineage_old, @lineage_new16 as lineage_new, @generation16 as generation  union all 
    select @rowguid17 as rowguid, @metadata_type17 as metadata_type, @lineage_old17 as lineage_old, @lineage_new17 as lineage_new, @generation17 as generation  union all 
    select @rowguid18 as rowguid, @metadata_type18 as metadata_type, @lineage_old18 as lineage_old, @lineage_new18 as lineage_new, @generation18 as generation  union all 
    select @rowguid19 as rowguid, @metadata_type19 as metadata_type, @lineage_old19 as lineage_old, @lineage_new19 as lineage_new, @generation19 as generation  union all 
    select @rowguid20 as rowguid, @metadata_type20 as metadata_type, @lineage_old20 as lineage_old, @lineage_new20 as lineage_new, @generation20 as generation 
 union all 
    select @rowguid21 as rowguid, @metadata_type21 as metadata_type, @lineage_old21 as lineage_old, @lineage_new21 as lineage_new, @generation21 as generation  union all 
    select @rowguid22 as rowguid, @metadata_type22 as metadata_type, @lineage_old22 as lineage_old, @lineage_new22 as lineage_new, @generation22 as generation  union all 
    select @rowguid23 as rowguid, @metadata_type23 as metadata_type, @lineage_old23 as lineage_old, @lineage_new23 as lineage_new, @generation23 as generation  union all 
    select @rowguid24 as rowguid, @metadata_type24 as metadata_type, @lineage_old24 as lineage_old, @lineage_new24 as lineage_new, @generation24 as generation  union all 
    select @rowguid25 as rowguid, @metadata_type25 as metadata_type, @lineage_old25 as lineage_old, @lineage_new25 as lineage_new, @generation25 as generation  union all 
    select @rowguid26 as rowguid, @metadata_type26 as metadata_type, @lineage_old26 as lineage_old, @lineage_new26 as lineage_new, @generation26 as generation  union all 
    select @rowguid27 as rowguid, @metadata_type27 as metadata_type, @lineage_old27 as lineage_old, @lineage_new27 as lineage_new, @generation27 as generation  union all 
    select @rowguid28 as rowguid, @metadata_type28 as metadata_type, @lineage_old28 as lineage_old, @lineage_new28 as lineage_new, @generation28 as generation  union all 
    select @rowguid29 as rowguid, @metadata_type29 as metadata_type, @lineage_old29 as lineage_old, @lineage_new29 as lineage_new, @generation29 as generation  union all 
    select @rowguid30 as rowguid, @metadata_type30 as metadata_type, @lineage_old30 as lineage_old, @lineage_new30 as lineage_new, @generation30 as generation 
 union all 
    select @rowguid31 as rowguid, @metadata_type31 as metadata_type, @lineage_old31 as lineage_old, @lineage_new31 as lineage_new, @generation31 as generation  union all 
    select @rowguid32 as rowguid, @metadata_type32 as metadata_type, @lineage_old32 as lineage_old, @lineage_new32 as lineage_new, @generation32 as generation  union all 
    select @rowguid33 as rowguid, @metadata_type33 as metadata_type, @lineage_old33 as lineage_old, @lineage_new33 as lineage_new, @generation33 as generation  union all 
    select @rowguid34 as rowguid, @metadata_type34 as metadata_type, @lineage_old34 as lineage_old, @lineage_new34 as lineage_new, @generation34 as generation  union all 
    select @rowguid35 as rowguid, @metadata_type35 as metadata_type, @lineage_old35 as lineage_old, @lineage_new35 as lineage_new, @generation35 as generation  union all 
    select @rowguid36 as rowguid, @metadata_type36 as metadata_type, @lineage_old36 as lineage_old, @lineage_new36 as lineage_new, @generation36 as generation  union all 
    select @rowguid37 as rowguid, @metadata_type37 as metadata_type, @lineage_old37 as lineage_old, @lineage_new37 as lineage_new, @generation37 as generation  union all 
    select @rowguid38 as rowguid, @metadata_type38 as metadata_type, @lineage_old38 as lineage_old, @lineage_new38 as lineage_new, @generation38 as generation  union all 
    select @rowguid39 as rowguid, @metadata_type39 as metadata_type, @lineage_old39 as lineage_old, @lineage_new39 as lineage_new, @generation39 as generation  union all 
    select @rowguid40 as rowguid, @metadata_type40 as metadata_type, @lineage_old40 as lineage_old, @lineage_new40 as lineage_new, @generation40 as generation 
 union all 
    select @rowguid41 as rowguid, @metadata_type41 as metadata_type, @lineage_old41 as lineage_old, @lineage_new41 as lineage_new, @generation41 as generation  union all 
    select @rowguid42 as rowguid, @metadata_type42 as metadata_type, @lineage_old42 as lineage_old, @lineage_new42 as lineage_new, @generation42 as generation  union all 
    select @rowguid43 as rowguid, @metadata_type43 as metadata_type, @lineage_old43 as lineage_old, @lineage_new43 as lineage_new, @generation43 as generation  union all 
    select @rowguid44 as rowguid, @metadata_type44 as metadata_type, @lineage_old44 as lineage_old, @lineage_new44 as lineage_new, @generation44 as generation  union all 
    select @rowguid45 as rowguid, @metadata_type45 as metadata_type, @lineage_old45 as lineage_old, @lineage_new45 as lineage_new, @generation45 as generation  union all 
    select @rowguid46 as rowguid, @metadata_type46 as metadata_type, @lineage_old46 as lineage_old, @lineage_new46 as lineage_new, @generation46 as generation  union all 
    select @rowguid47 as rowguid, @metadata_type47 as metadata_type, @lineage_old47 as lineage_old, @lineage_new47 as lineage_new, @generation47 as generation  union all 
    select @rowguid48 as rowguid, @metadata_type48 as metadata_type, @lineage_old48 as lineage_old, @lineage_new48 as lineage_new, @generation48 as generation  union all 
    select @rowguid49 as rowguid, @metadata_type49 as metadata_type, @lineage_old49 as lineage_old, @lineage_new49 as lineage_new, @generation49 as generation  union all 
    select @rowguid50 as rowguid, @metadata_type50 as metadata_type, @lineage_old50 as lineage_old, @lineage_new50 as lineage_new, @generation50 as generation 
 union all 
    select @rowguid51 as rowguid, @metadata_type51 as metadata_type, @lineage_old51 as lineage_old, @lineage_new51 as lineage_new, @generation51 as generation  union all 
    select @rowguid52 as rowguid, @metadata_type52 as metadata_type, @lineage_old52 as lineage_old, @lineage_new52 as lineage_new, @generation52 as generation  union all 
    select @rowguid53 as rowguid, @metadata_type53 as metadata_type, @lineage_old53 as lineage_old, @lineage_new53 as lineage_new, @generation53 as generation  union all 
    select @rowguid54 as rowguid, @metadata_type54 as metadata_type, @lineage_old54 as lineage_old, @lineage_new54 as lineage_new, @generation54 as generation  union all 
    select @rowguid55 as rowguid, @metadata_type55 as metadata_type, @lineage_old55 as lineage_old, @lineage_new55 as lineage_new, @generation55 as generation  union all 
    select @rowguid56 as rowguid, @metadata_type56 as metadata_type, @lineage_old56 as lineage_old, @lineage_new56 as lineage_new, @generation56 as generation  union all 
    select @rowguid57 as rowguid, @metadata_type57 as metadata_type, @lineage_old57 as lineage_old, @lineage_new57 as lineage_new, @generation57 as generation  union all 
    select @rowguid58 as rowguid, @metadata_type58 as metadata_type, @lineage_old58 as lineage_old, @lineage_new58 as lineage_new, @generation58 as generation  union all 
    select @rowguid59 as rowguid, @metadata_type59 as metadata_type, @lineage_old59 as lineage_old, @lineage_new59 as lineage_new, @generation59 as generation  union all 
    select @rowguid60 as rowguid, @metadata_type60 as metadata_type, @lineage_old60 as lineage_old, @lineage_new60 as lineage_new, @generation60 as generation 
 union all 
    select @rowguid61 as rowguid, @metadata_type61 as metadata_type, @lineage_old61 as lineage_old, @lineage_new61 as lineage_new, @generation61 as generation  union all 
    select @rowguid62 as rowguid, @metadata_type62 as metadata_type, @lineage_old62 as lineage_old, @lineage_new62 as lineage_new, @generation62 as generation  union all 
    select @rowguid63 as rowguid, @metadata_type63 as metadata_type, @lineage_old63 as lineage_old, @lineage_new63 as lineage_new, @generation63 as generation  union all 
    select @rowguid64 as rowguid, @metadata_type64 as metadata_type, @lineage_old64 as lineage_old, @lineage_new64 as lineage_new, @generation64 as generation  union all 
    select @rowguid65 as rowguid, @metadata_type65 as metadata_type, @lineage_old65 as lineage_old, @lineage_new65 as lineage_new, @generation65 as generation  union all 
    select @rowguid66 as rowguid, @metadata_type66 as metadata_type, @lineage_old66 as lineage_old, @lineage_new66 as lineage_new, @generation66 as generation  union all 
    select @rowguid67 as rowguid, @metadata_type67 as metadata_type, @lineage_old67 as lineage_old, @lineage_new67 as lineage_new, @generation67 as generation  union all 
    select @rowguid68 as rowguid, @metadata_type68 as metadata_type, @lineage_old68 as lineage_old, @lineage_new68 as lineage_new, @generation68 as generation  union all 
    select @rowguid69 as rowguid, @metadata_type69 as metadata_type, @lineage_old69 as lineage_old, @lineage_new69 as lineage_new, @generation69 as generation  union all 
    select @rowguid70 as rowguid, @metadata_type70 as metadata_type, @lineage_old70 as lineage_old, @lineage_new70 as lineage_new, @generation70 as generation 
 union all 
    select @rowguid71 as rowguid, @metadata_type71 as metadata_type, @lineage_old71 as lineage_old, @lineage_new71 as lineage_new, @generation71 as generation  union all 
    select @rowguid72 as rowguid, @metadata_type72 as metadata_type, @lineage_old72 as lineage_old, @lineage_new72 as lineage_new, @generation72 as generation  union all 
    select @rowguid73 as rowguid, @metadata_type73 as metadata_type, @lineage_old73 as lineage_old, @lineage_new73 as lineage_new, @generation73 as generation  union all 
    select @rowguid74 as rowguid, @metadata_type74 as metadata_type, @lineage_old74 as lineage_old, @lineage_new74 as lineage_new, @generation74 as generation  union all 
    select @rowguid75 as rowguid, @metadata_type75 as metadata_type, @lineage_old75 as lineage_old, @lineage_new75 as lineage_new, @generation75 as generation  union all 
    select @rowguid76 as rowguid, @metadata_type76 as metadata_type, @lineage_old76 as lineage_old, @lineage_new76 as lineage_new, @generation76 as generation  union all 
    select @rowguid77 as rowguid, @metadata_type77 as metadata_type, @lineage_old77 as lineage_old, @lineage_new77 as lineage_new, @generation77 as generation  union all 
    select @rowguid78 as rowguid, @metadata_type78 as metadata_type, @lineage_old78 as lineage_old, @lineage_new78 as lineage_new, @generation78 as generation  union all 
    select @rowguid79 as rowguid, @metadata_type79 as metadata_type, @lineage_old79 as lineage_old, @lineage_new79 as lineage_new, @generation79 as generation  union all 
    select @rowguid80 as rowguid, @metadata_type80 as metadata_type, @lineage_old80 as lineage_old, @lineage_new80 as lineage_new, @generation80 as generation 
 union all 
    select @rowguid81 as rowguid, @metadata_type81 as metadata_type, @lineage_old81 as lineage_old, @lineage_new81 as lineage_new, @generation81 as generation  union all 
    select @rowguid82 as rowguid, @metadata_type82 as metadata_type, @lineage_old82 as lineage_old, @lineage_new82 as lineage_new, @generation82 as generation  union all 
    select @rowguid83 as rowguid, @metadata_type83 as metadata_type, @lineage_old83 as lineage_old, @lineage_new83 as lineage_new, @generation83 as generation  union all 
    select @rowguid84 as rowguid, @metadata_type84 as metadata_type, @lineage_old84 as lineage_old, @lineage_new84 as lineage_new, @generation84 as generation  union all 
    select @rowguid85 as rowguid, @metadata_type85 as metadata_type, @lineage_old85 as lineage_old, @lineage_new85 as lineage_new, @generation85 as generation  union all 
    select @rowguid86 as rowguid, @metadata_type86 as metadata_type, @lineage_old86 as lineage_old, @lineage_new86 as lineage_new, @generation86 as generation  union all 
    select @rowguid87 as rowguid, @metadata_type87 as metadata_type, @lineage_old87 as lineage_old, @lineage_new87 as lineage_new, @generation87 as generation  union all 
    select @rowguid88 as rowguid, @metadata_type88 as metadata_type, @lineage_old88 as lineage_old, @lineage_new88 as lineage_new, @generation88 as generation  union all 
    select @rowguid89 as rowguid, @metadata_type89 as metadata_type, @lineage_old89 as lineage_old, @lineage_new89 as lineage_new, @generation89 as generation  union all 
    select @rowguid90 as rowguid, @metadata_type90 as metadata_type, @lineage_old90 as lineage_old, @lineage_new90 as lineage_new, @generation90 as generation 
 union all 
    select @rowguid91 as rowguid, @metadata_type91 as metadata_type, @lineage_old91 as lineage_old, @lineage_new91 as lineage_new, @generation91 as generation  union all 
    select @rowguid92 as rowguid, @metadata_type92 as metadata_type, @lineage_old92 as lineage_old, @lineage_new92 as lineage_new, @generation92 as generation  union all 
    select @rowguid93 as rowguid, @metadata_type93 as metadata_type, @lineage_old93 as lineage_old, @lineage_new93 as lineage_new, @generation93 as generation  union all 
    select @rowguid94 as rowguid, @metadata_type94 as metadata_type, @lineage_old94 as lineage_old, @lineage_new94 as lineage_new, @generation94 as generation  union all 
    select @rowguid95 as rowguid, @metadata_type95 as metadata_type, @lineage_old95 as lineage_old, @lineage_new95 as lineage_new, @generation95 as generation  union all 
    select @rowguid96 as rowguid, @metadata_type96 as metadata_type, @lineage_old96 as lineage_old, @lineage_new96 as lineage_new, @generation96 as generation  union all 
    select @rowguid97 as rowguid, @metadata_type97 as metadata_type, @lineage_old97 as lineage_old, @lineage_new97 as lineage_new, @generation97 as generation  union all 
    select @rowguid98 as rowguid, @metadata_type98 as metadata_type, @lineage_old98 as lineage_old, @lineage_new98 as lineage_new, @generation98 as generation  union all 
    select @rowguid99 as rowguid, @metadata_type99 as metadata_type, @lineage_old99 as lineage_old, @lineage_new99 as lineage_new, @generation99 as generation  union all 
    select @rowguid100 as rowguid, @metadata_type100 as metadata_type, @lineage_old100 as lineage_old, @lineage_new100 as lineage_new, @generation100 as generation 

        ) as rows
        inner join dbo.MSmerge_past_partition_mappings ppm with (rowlock) 
        on ppm.rowguid = rows.rowguid and ppm.tablenick = 49871000 
        and ppm.generation = 0
        and rows.rowguid is not NULL
        and rows.lineage_new is not null
        option (force order, loop join)
        if @error<>0
                goto Failure

    if @tomb_rows_updated <> @rowstobedeleted
    begin
        -- now insert rows that are not in tombstone
        insert into dbo.MSmerge_tombstone with (rowlock)
            (rowguid, tablenick, type, generation, lineage)
        select rows.rowguid, 49871000, 
               case when (rows.metadata_type=5 or rows.metadata_type=6) then rows.metadata_type else 1 end, 
               rows.generation, rows.lineage_new
        from 
        (

    select @rowguid1 as rowguid, @metadata_type1 as metadata_type, @lineage_old1 as lineage_old, @lineage_new1 as lineage_new, @generation1 as generation  union all 
    select @rowguid2 as rowguid, @metadata_type2 as metadata_type, @lineage_old2 as lineage_old, @lineage_new2 as lineage_new, @generation2 as generation  union all 
    select @rowguid3 as rowguid, @metadata_type3 as metadata_type, @lineage_old3 as lineage_old, @lineage_new3 as lineage_new, @generation3 as generation  union all 
    select @rowguid4 as rowguid, @metadata_type4 as metadata_type, @lineage_old4 as lineage_old, @lineage_new4 as lineage_new, @generation4 as generation  union all 
    select @rowguid5 as rowguid, @metadata_type5 as metadata_type, @lineage_old5 as lineage_old, @lineage_new5 as lineage_new, @generation5 as generation  union all 
    select @rowguid6 as rowguid, @metadata_type6 as metadata_type, @lineage_old6 as lineage_old, @lineage_new6 as lineage_new, @generation6 as generation  union all 
    select @rowguid7 as rowguid, @metadata_type7 as metadata_type, @lineage_old7 as lineage_old, @lineage_new7 as lineage_new, @generation7 as generation  union all 
    select @rowguid8 as rowguid, @metadata_type8 as metadata_type, @lineage_old8 as lineage_old, @lineage_new8 as lineage_new, @generation8 as generation  union all 
    select @rowguid9 as rowguid, @metadata_type9 as metadata_type, @lineage_old9 as lineage_old, @lineage_new9 as lineage_new, @generation9 as generation  union all 
    select @rowguid10 as rowguid, @metadata_type10 as metadata_type, @lineage_old10 as lineage_old, @lineage_new10 as lineage_new, @generation10 as generation 
 union all 
    select @rowguid11 as rowguid, @metadata_type11 as metadata_type, @lineage_old11 as lineage_old, @lineage_new11 as lineage_new, @generation11 as generation  union all 
    select @rowguid12 as rowguid, @metadata_type12 as metadata_type, @lineage_old12 as lineage_old, @lineage_new12 as lineage_new, @generation12 as generation  union all 
    select @rowguid13 as rowguid, @metadata_type13 as metadata_type, @lineage_old13 as lineage_old, @lineage_new13 as lineage_new, @generation13 as generation  union all 
    select @rowguid14 as rowguid, @metadata_type14 as metadata_type, @lineage_old14 as lineage_old, @lineage_new14 as lineage_new, @generation14 as generation  union all 
    select @rowguid15 as rowguid, @metadata_type15 as metadata_type, @lineage_old15 as lineage_old, @lineage_new15 as lineage_new, @generation15 as generation  union all 
    select @rowguid16 as rowguid, @metadata_type16 as metadata_type, @lineage_old16 as lineage_old, @lineage_new16 as lineage_new, @generation16 as generation  union all 
    select @rowguid17 as rowguid, @metadata_type17 as metadata_type, @lineage_old17 as lineage_old, @lineage_new17 as lineage_new, @generation17 as generation  union all 
    select @rowguid18 as rowguid, @metadata_type18 as metadata_type, @lineage_old18 as lineage_old, @lineage_new18 as lineage_new, @generation18 as generation  union all 
    select @rowguid19 as rowguid, @metadata_type19 as metadata_type, @lineage_old19 as lineage_old, @lineage_new19 as lineage_new, @generation19 as generation  union all 
    select @rowguid20 as rowguid, @metadata_type20 as metadata_type, @lineage_old20 as lineage_old, @lineage_new20 as lineage_new, @generation20 as generation 
 union all 
    select @rowguid21 as rowguid, @metadata_type21 as metadata_type, @lineage_old21 as lineage_old, @lineage_new21 as lineage_new, @generation21 as generation  union all 
    select @rowguid22 as rowguid, @metadata_type22 as metadata_type, @lineage_old22 as lineage_old, @lineage_new22 as lineage_new, @generation22 as generation  union all 
    select @rowguid23 as rowguid, @metadata_type23 as metadata_type, @lineage_old23 as lineage_old, @lineage_new23 as lineage_new, @generation23 as generation  union all 
    select @rowguid24 as rowguid, @metadata_type24 as metadata_type, @lineage_old24 as lineage_old, @lineage_new24 as lineage_new, @generation24 as generation  union all 
    select @rowguid25 as rowguid, @metadata_type25 as metadata_type, @lineage_old25 as lineage_old, @lineage_new25 as lineage_new, @generation25 as generation  union all 
    select @rowguid26 as rowguid, @metadata_type26 as metadata_type, @lineage_old26 as lineage_old, @lineage_new26 as lineage_new, @generation26 as generation  union all 
    select @rowguid27 as rowguid, @metadata_type27 as metadata_type, @lineage_old27 as lineage_old, @lineage_new27 as lineage_new, @generation27 as generation  union all 
    select @rowguid28 as rowguid, @metadata_type28 as metadata_type, @lineage_old28 as lineage_old, @lineage_new28 as lineage_new, @generation28 as generation  union all 
    select @rowguid29 as rowguid, @metadata_type29 as metadata_type, @lineage_old29 as lineage_old, @lineage_new29 as lineage_new, @generation29 as generation  union all 
    select @rowguid30 as rowguid, @metadata_type30 as metadata_type, @lineage_old30 as lineage_old, @lineage_new30 as lineage_new, @generation30 as generation 
 union all 
    select @rowguid31 as rowguid, @metadata_type31 as metadata_type, @lineage_old31 as lineage_old, @lineage_new31 as lineage_new, @generation31 as generation  union all 
    select @rowguid32 as rowguid, @metadata_type32 as metadata_type, @lineage_old32 as lineage_old, @lineage_new32 as lineage_new, @generation32 as generation  union all 
    select @rowguid33 as rowguid, @metadata_type33 as metadata_type, @lineage_old33 as lineage_old, @lineage_new33 as lineage_new, @generation33 as generation  union all 
    select @rowguid34 as rowguid, @metadata_type34 as metadata_type, @lineage_old34 as lineage_old, @lineage_new34 as lineage_new, @generation34 as generation  union all 
    select @rowguid35 as rowguid, @metadata_type35 as metadata_type, @lineage_old35 as lineage_old, @lineage_new35 as lineage_new, @generation35 as generation  union all 
    select @rowguid36 as rowguid, @metadata_type36 as metadata_type, @lineage_old36 as lineage_old, @lineage_new36 as lineage_new, @generation36 as generation  union all 
    select @rowguid37 as rowguid, @metadata_type37 as metadata_type, @lineage_old37 as lineage_old, @lineage_new37 as lineage_new, @generation37 as generation  union all 
    select @rowguid38 as rowguid, @metadata_type38 as metadata_type, @lineage_old38 as lineage_old, @lineage_new38 as lineage_new, @generation38 as generation  union all 
    select @rowguid39 as rowguid, @metadata_type39 as metadata_type, @lineage_old39 as lineage_old, @lineage_new39 as lineage_new, @generation39 as generation  union all 
    select @rowguid40 as rowguid, @metadata_type40 as metadata_type, @lineage_old40 as lineage_old, @lineage_new40 as lineage_new, @generation40 as generation 
 union all 
    select @rowguid41 as rowguid, @metadata_type41 as metadata_type, @lineage_old41 as lineage_old, @lineage_new41 as lineage_new, @generation41 as generation  union all 
    select @rowguid42 as rowguid, @metadata_type42 as metadata_type, @lineage_old42 as lineage_old, @lineage_new42 as lineage_new, @generation42 as generation  union all 
    select @rowguid43 as rowguid, @metadata_type43 as metadata_type, @lineage_old43 as lineage_old, @lineage_new43 as lineage_new, @generation43 as generation  union all 
    select @rowguid44 as rowguid, @metadata_type44 as metadata_type, @lineage_old44 as lineage_old, @lineage_new44 as lineage_new, @generation44 as generation  union all 
    select @rowguid45 as rowguid, @metadata_type45 as metadata_type, @lineage_old45 as lineage_old, @lineage_new45 as lineage_new, @generation45 as generation  union all 
    select @rowguid46 as rowguid, @metadata_type46 as metadata_type, @lineage_old46 as lineage_old, @lineage_new46 as lineage_new, @generation46 as generation  union all 
    select @rowguid47 as rowguid, @metadata_type47 as metadata_type, @lineage_old47 as lineage_old, @lineage_new47 as lineage_new, @generation47 as generation  union all 
    select @rowguid48 as rowguid, @metadata_type48 as metadata_type, @lineage_old48 as lineage_old, @lineage_new48 as lineage_new, @generation48 as generation  union all 
    select @rowguid49 as rowguid, @metadata_type49 as metadata_type, @lineage_old49 as lineage_old, @lineage_new49 as lineage_new, @generation49 as generation  union all 
    select @rowguid50 as rowguid, @metadata_type50 as metadata_type, @lineage_old50 as lineage_old, @lineage_new50 as lineage_new, @generation50 as generation 
 union all 
    select @rowguid51 as rowguid, @metadata_type51 as metadata_type, @lineage_old51 as lineage_old, @lineage_new51 as lineage_new, @generation51 as generation  union all 
    select @rowguid52 as rowguid, @metadata_type52 as metadata_type, @lineage_old52 as lineage_old, @lineage_new52 as lineage_new, @generation52 as generation  union all 
    select @rowguid53 as rowguid, @metadata_type53 as metadata_type, @lineage_old53 as lineage_old, @lineage_new53 as lineage_new, @generation53 as generation  union all 
    select @rowguid54 as rowguid, @metadata_type54 as metadata_type, @lineage_old54 as lineage_old, @lineage_new54 as lineage_new, @generation54 as generation  union all 
    select @rowguid55 as rowguid, @metadata_type55 as metadata_type, @lineage_old55 as lineage_old, @lineage_new55 as lineage_new, @generation55 as generation  union all 
    select @rowguid56 as rowguid, @metadata_type56 as metadata_type, @lineage_old56 as lineage_old, @lineage_new56 as lineage_new, @generation56 as generation  union all 
    select @rowguid57 as rowguid, @metadata_type57 as metadata_type, @lineage_old57 as lineage_old, @lineage_new57 as lineage_new, @generation57 as generation  union all 
    select @rowguid58 as rowguid, @metadata_type58 as metadata_type, @lineage_old58 as lineage_old, @lineage_new58 as lineage_new, @generation58 as generation  union all 
    select @rowguid59 as rowguid, @metadata_type59 as metadata_type, @lineage_old59 as lineage_old, @lineage_new59 as lineage_new, @generation59 as generation  union all 
    select @rowguid60 as rowguid, @metadata_type60 as metadata_type, @lineage_old60 as lineage_old, @lineage_new60 as lineage_new, @generation60 as generation 
 union all 
    select @rowguid61 as rowguid, @metadata_type61 as metadata_type, @lineage_old61 as lineage_old, @lineage_new61 as lineage_new, @generation61 as generation  union all 
    select @rowguid62 as rowguid, @metadata_type62 as metadata_type, @lineage_old62 as lineage_old, @lineage_new62 as lineage_new, @generation62 as generation  union all 
    select @rowguid63 as rowguid, @metadata_type63 as metadata_type, @lineage_old63 as lineage_old, @lineage_new63 as lineage_new, @generation63 as generation  union all 
    select @rowguid64 as rowguid, @metadata_type64 as metadata_type, @lineage_old64 as lineage_old, @lineage_new64 as lineage_new, @generation64 as generation  union all 
    select @rowguid65 as rowguid, @metadata_type65 as metadata_type, @lineage_old65 as lineage_old, @lineage_new65 as lineage_new, @generation65 as generation  union all 
    select @rowguid66 as rowguid, @metadata_type66 as metadata_type, @lineage_old66 as lineage_old, @lineage_new66 as lineage_new, @generation66 as generation  union all 
    select @rowguid67 as rowguid, @metadata_type67 as metadata_type, @lineage_old67 as lineage_old, @lineage_new67 as lineage_new, @generation67 as generation  union all 
    select @rowguid68 as rowguid, @metadata_type68 as metadata_type, @lineage_old68 as lineage_old, @lineage_new68 as lineage_new, @generation68 as generation  union all 
    select @rowguid69 as rowguid, @metadata_type69 as metadata_type, @lineage_old69 as lineage_old, @lineage_new69 as lineage_new, @generation69 as generation  union all 
    select @rowguid70 as rowguid, @metadata_type70 as metadata_type, @lineage_old70 as lineage_old, @lineage_new70 as lineage_new, @generation70 as generation 
 union all 
    select @rowguid71 as rowguid, @metadata_type71 as metadata_type, @lineage_old71 as lineage_old, @lineage_new71 as lineage_new, @generation71 as generation  union all 
    select @rowguid72 as rowguid, @metadata_type72 as metadata_type, @lineage_old72 as lineage_old, @lineage_new72 as lineage_new, @generation72 as generation  union all 
    select @rowguid73 as rowguid, @metadata_type73 as metadata_type, @lineage_old73 as lineage_old, @lineage_new73 as lineage_new, @generation73 as generation  union all 
    select @rowguid74 as rowguid, @metadata_type74 as metadata_type, @lineage_old74 as lineage_old, @lineage_new74 as lineage_new, @generation74 as generation  union all 
    select @rowguid75 as rowguid, @metadata_type75 as metadata_type, @lineage_old75 as lineage_old, @lineage_new75 as lineage_new, @generation75 as generation  union all 
    select @rowguid76 as rowguid, @metadata_type76 as metadata_type, @lineage_old76 as lineage_old, @lineage_new76 as lineage_new, @generation76 as generation  union all 
    select @rowguid77 as rowguid, @metadata_type77 as metadata_type, @lineage_old77 as lineage_old, @lineage_new77 as lineage_new, @generation77 as generation  union all 
    select @rowguid78 as rowguid, @metadata_type78 as metadata_type, @lineage_old78 as lineage_old, @lineage_new78 as lineage_new, @generation78 as generation  union all 
    select @rowguid79 as rowguid, @metadata_type79 as metadata_type, @lineage_old79 as lineage_old, @lineage_new79 as lineage_new, @generation79 as generation  union all 
    select @rowguid80 as rowguid, @metadata_type80 as metadata_type, @lineage_old80 as lineage_old, @lineage_new80 as lineage_new, @generation80 as generation 
 union all 
    select @rowguid81 as rowguid, @metadata_type81 as metadata_type, @lineage_old81 as lineage_old, @lineage_new81 as lineage_new, @generation81 as generation  union all 
    select @rowguid82 as rowguid, @metadata_type82 as metadata_type, @lineage_old82 as lineage_old, @lineage_new82 as lineage_new, @generation82 as generation  union all 
    select @rowguid83 as rowguid, @metadata_type83 as metadata_type, @lineage_old83 as lineage_old, @lineage_new83 as lineage_new, @generation83 as generation  union all 
    select @rowguid84 as rowguid, @metadata_type84 as metadata_type, @lineage_old84 as lineage_old, @lineage_new84 as lineage_new, @generation84 as generation  union all 
    select @rowguid85 as rowguid, @metadata_type85 as metadata_type, @lineage_old85 as lineage_old, @lineage_new85 as lineage_new, @generation85 as generation  union all 
    select @rowguid86 as rowguid, @metadata_type86 as metadata_type, @lineage_old86 as lineage_old, @lineage_new86 as lineage_new, @generation86 as generation  union all 
    select @rowguid87 as rowguid, @metadata_type87 as metadata_type, @lineage_old87 as lineage_old, @lineage_new87 as lineage_new, @generation87 as generation  union all 
    select @rowguid88 as rowguid, @metadata_type88 as metadata_type, @lineage_old88 as lineage_old, @lineage_new88 as lineage_new, @generation88 as generation  union all 
    select @rowguid89 as rowguid, @metadata_type89 as metadata_type, @lineage_old89 as lineage_old, @lineage_new89 as lineage_new, @generation89 as generation  union all 
    select @rowguid90 as rowguid, @metadata_type90 as metadata_type, @lineage_old90 as lineage_old, @lineage_new90 as lineage_new, @generation90 as generation 
 union all 
    select @rowguid91 as rowguid, @metadata_type91 as metadata_type, @lineage_old91 as lineage_old, @lineage_new91 as lineage_new, @generation91 as generation  union all 
    select @rowguid92 as rowguid, @metadata_type92 as metadata_type, @lineage_old92 as lineage_old, @lineage_new92 as lineage_new, @generation92 as generation  union all 
    select @rowguid93 as rowguid, @metadata_type93 as metadata_type, @lineage_old93 as lineage_old, @lineage_new93 as lineage_new, @generation93 as generation  union all 
    select @rowguid94 as rowguid, @metadata_type94 as metadata_type, @lineage_old94 as lineage_old, @lineage_new94 as lineage_new, @generation94 as generation  union all 
    select @rowguid95 as rowguid, @metadata_type95 as metadata_type, @lineage_old95 as lineage_old, @lineage_new95 as lineage_new, @generation95 as generation  union all 
    select @rowguid96 as rowguid, @metadata_type96 as metadata_type, @lineage_old96 as lineage_old, @lineage_new96 as lineage_new, @generation96 as generation  union all 
    select @rowguid97 as rowguid, @metadata_type97 as metadata_type, @lineage_old97 as lineage_old, @lineage_new97 as lineage_new, @generation97 as generation  union all 
    select @rowguid98 as rowguid, @metadata_type98 as metadata_type, @lineage_old98 as lineage_old, @lineage_new98 as lineage_new, @generation98 as generation  union all 
    select @rowguid99 as rowguid, @metadata_type99 as metadata_type, @lineage_old99 as lineage_old, @lineage_new99 as lineage_new, @generation99 as generation  union all 
    select @rowguid100 as rowguid, @metadata_type100 as metadata_type, @lineage_old100 as lineage_old, @lineage_new100 as lineage_new, @generation100 as generation 

        ) as rows
        left outer join dbo.MSmerge_tombstone tomb with (rowlock) 
        on tomb.rowguid = rows.rowguid 
        and tomb.tablenick = 49871000
        and rows.rowguid is not NULL and rows.lineage_new is not null
        where tomb.rowguid is NULL 
        and rows.rowguid is not NULL and rows.lineage_new is not null
        
        if @@error<>0
            goto Failure

        -- now delete the contents rows
        delete dbo.MSmerge_contents with (rowlock)
        from 
        (

         select @rowguid1 as rowguid union all 
         select @rowguid2 as rowguid union all 
         select @rowguid3 as rowguid union all 
         select @rowguid4 as rowguid union all 
         select @rowguid5 as rowguid union all 
         select @rowguid6 as rowguid union all 
         select @rowguid7 as rowguid union all 
         select @rowguid8 as rowguid union all 
         select @rowguid9 as rowguid union all 
         select @rowguid10 as rowguid union all 
         select @rowguid11 as rowguid union all 
         select @rowguid12 as rowguid union all 
         select @rowguid13 as rowguid union all 
         select @rowguid14 as rowguid union all 
         select @rowguid15 as rowguid union all 
         select @rowguid16 as rowguid union all 
         select @rowguid17 as rowguid union all 
         select @rowguid18 as rowguid union all 
         select @rowguid19 as rowguid union all 
         select @rowguid20 as rowguid union all 
         select @rowguid21 as rowguid union all 
         select @rowguid22 as rowguid union all 
         select @rowguid23 as rowguid union all 
         select @rowguid24 as rowguid union all 
         select @rowguid25 as rowguid union all 
         select @rowguid26 as rowguid union all 
         select @rowguid27 as rowguid union all 
         select @rowguid28 as rowguid union all 
         select @rowguid29 as rowguid union all 
         select @rowguid30 as rowguid union all 
         select @rowguid31 as rowguid union all 
         select @rowguid32 as rowguid union all 
         select @rowguid33 as rowguid union all 
         select @rowguid34 as rowguid union all 
         select @rowguid35 as rowguid union all 
         select @rowguid36 as rowguid union all 
         select @rowguid37 as rowguid union all 
         select @rowguid38 as rowguid union all 
         select @rowguid39 as rowguid union all 
         select @rowguid40 as rowguid union all 
         select @rowguid41 as rowguid union all 
         select @rowguid42 as rowguid union all 
         select @rowguid43 as rowguid union all 
         select @rowguid44 as rowguid union all 
         select @rowguid45 as rowguid union all 
         select @rowguid46 as rowguid union all 
         select @rowguid47 as rowguid union all 
         select @rowguid48 as rowguid union all 
         select @rowguid49 as rowguid union all 
         select @rowguid50 as rowguid union all

         select @rowguid51 as rowguid union all 
         select @rowguid52 as rowguid union all 
         select @rowguid53 as rowguid union all 
         select @rowguid54 as rowguid union all 
         select @rowguid55 as rowguid union all 
         select @rowguid56 as rowguid union all 
         select @rowguid57 as rowguid union all 
         select @rowguid58 as rowguid union all 
         select @rowguid59 as rowguid union all 
         select @rowguid60 as rowguid union all 
         select @rowguid61 as rowguid union all 
         select @rowguid62 as rowguid union all 
         select @rowguid63 as rowguid union all 
         select @rowguid64 as rowguid union all 
         select @rowguid65 as rowguid union all 
         select @rowguid66 as rowguid union all 
         select @rowguid67 as rowguid union all 
         select @rowguid68 as rowguid union all 
         select @rowguid69 as rowguid union all 
         select @rowguid70 as rowguid union all 
         select @rowguid71 as rowguid union all 
         select @rowguid72 as rowguid union all 
         select @rowguid73 as rowguid union all 
         select @rowguid74 as rowguid union all 
         select @rowguid75 as rowguid union all 
         select @rowguid76 as rowguid union all 
         select @rowguid77 as rowguid union all 
         select @rowguid78 as rowguid union all 
         select @rowguid79 as rowguid union all 
         select @rowguid80 as rowguid union all 
         select @rowguid81 as rowguid union all 
         select @rowguid82 as rowguid union all 
         select @rowguid83 as rowguid union all 
         select @rowguid84 as rowguid union all 
         select @rowguid85 as rowguid union all 
         select @rowguid86 as rowguid union all 
         select @rowguid87 as rowguid union all 
         select @rowguid88 as rowguid union all 
         select @rowguid89 as rowguid union all 
         select @rowguid90 as rowguid union all 
         select @rowguid91 as rowguid union all 
         select @rowguid92 as rowguid union all 
         select @rowguid93 as rowguid union all 
         select @rowguid94 as rowguid union all 
         select @rowguid95 as rowguid union all 
         select @rowguid96 as rowguid union all 
         select @rowguid97 as rowguid union all 
         select @rowguid98 as rowguid union all 
         select @rowguid99 as rowguid union all 
         select @rowguid100 as rowguid

        ) as rows, dbo.MSmerge_contents cont with (rowlock)
        where cont.rowguid = rows.rowguid and cont.tablenick = 49871000
            and rows.rowguid is not NULL
        option (force order, loop join)
        if @@error<>0 
            goto Failure
    end

    exec @retcode = sys.sp_MSdeletemetadataactionrequest '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800', 49871000, 
        @rowguid1, 
        @rowguid2, 
        @rowguid3, 
        @rowguid4, 
        @rowguid5, 
        @rowguid6, 
        @rowguid7, 
        @rowguid8, 
        @rowguid9, 
        @rowguid10, 
        @rowguid11, 
        @rowguid12, 
        @rowguid13, 
        @rowguid14, 
        @rowguid15, 
        @rowguid16, 
        @rowguid17, 
        @rowguid18, 
        @rowguid19, 
        @rowguid20, 
        @rowguid21, 
        @rowguid22, 
        @rowguid23, 
        @rowguid24, 
        @rowguid25, 
        @rowguid26, 
        @rowguid27, 
        @rowguid28, 
        @rowguid29, 
        @rowguid30, 
        @rowguid31, 
        @rowguid32, 
        @rowguid33, 
        @rowguid34, 
        @rowguid35, 
        @rowguid36, 
        @rowguid37, 
        @rowguid38, 
        @rowguid39, 
        @rowguid40, 
        @rowguid41, 
        @rowguid42, 
        @rowguid43, 
        @rowguid44, 
        @rowguid45, 
        @rowguid46, 
        @rowguid47, 
        @rowguid48, 
        @rowguid49, 
        @rowguid50, 
        @rowguid51, 
        @rowguid52, 
        @rowguid53, 
        @rowguid54, 
        @rowguid55, 
        @rowguid56, 
        @rowguid57, 
        @rowguid58, 
        @rowguid59, 
        @rowguid60, 
        @rowguid61, 
        @rowguid62, 
        @rowguid63, 
        @rowguid64, 
        @rowguid65, 
        @rowguid66, 
        @rowguid67, 
        @rowguid68, 
        @rowguid69, 
        @rowguid70, 
        @rowguid71, 
        @rowguid72, 
        @rowguid73, 
        @rowguid74, 
        @rowguid75, 
        @rowguid76, 
        @rowguid77, 
        @rowguid78, 
        @rowguid79, 
        @rowguid80, 
        @rowguid81, 
        @rowguid82, 
        @rowguid83, 
        @rowguid84, 
        @rowguid85, 
        @rowguid86, 
        @rowguid87, 
        @rowguid88, 
        @rowguid89, 
        @rowguid90, 
        @rowguid91, 
        @rowguid92, 
        @rowguid93, 
        @rowguid94, 
        @rowguid95, 
        @rowguid96, 
        @rowguid97, 
        @rowguid98, 
        @rowguid99, 
        @rowguid100
    if @retcode<>0 or @@error<>0
        goto Failure


    commit tran
    return 1

Failure:
    rollback tran batchdeleteproc
    commit tran
    return 0
end

go
create procedure dbo.[MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch] (
        @rows_tobe_inserted int,
        @partition_id int = null 
,
    @rowguid1 uniqueidentifier = NULL,
    @generation1 bigint = NULL,
    @lineage1 varbinary(311) = NULL,
    @colv1 varbinary(1) = NULL,
    @p1 varchar(10) = NULL,
    @p2 varchar(10) = NULL,
    @p3 varchar(10) = NULL,
    @p4 nvarchar(50) = NULL,
    @p5 int = NULL,
    @p6 nvarchar(50) = NULL,
    @p7 int = NULL,
    @p8 varchar(50) = NULL,
    @p9 nvarchar(max) = NULL,
    @p10 nvarchar(50) = NULL,
    @p11 nvarchar(50) = NULL,
    @p12 nvarchar(50) = NULL,
    @p13 uniqueidentifier = NULL,
    @rowguid2 uniqueidentifier = NULL,
    @generation2 bigint = NULL,
    @lineage2 varbinary(311) = NULL,
    @colv2 varbinary(1) = NULL,
    @p14 varchar(10) = NULL,
    @p15 varchar(10) = NULL,
    @p16 varchar(10) = NULL,
    @p17 nvarchar(50) = NULL,
    @p18 int = NULL,
    @p19 nvarchar(50) = NULL,
    @p20 int = NULL,
    @p21 varchar(50) = NULL,
    @p22 nvarchar(max) = NULL,
    @p23 nvarchar(50) = NULL,
    @p24 nvarchar(50) = NULL,
    @p25 nvarchar(50) = NULL,
    @p26 uniqueidentifier = NULL,
    @rowguid3 uniqueidentifier = NULL,
    @generation3 bigint = NULL,
    @lineage3 varbinary(311) = NULL,
    @colv3 varbinary(1) = NULL,
    @p27 varchar(10) = NULL,
    @p28 varchar(10) = NULL,
    @p29 varchar(10) = NULL,
    @p30 nvarchar(50) = NULL,
    @p31 int = NULL,
    @p32 nvarchar(50) = NULL,
    @p33 int = NULL,
    @p34 varchar(50) = NULL,
    @p35 nvarchar(max) = NULL,
    @p36 nvarchar(50) = NULL,
    @p37 nvarchar(50) = NULL,
    @p38 nvarchar(50) = NULL,
    @p39 uniqueidentifier = NULL,
    @rowguid4 uniqueidentifier = NULL,
    @generation4 bigint = NULL,
    @lineage4 varbinary(311) = NULL,
    @colv4 varbinary(1) = NULL,
    @p40 varchar(10) = NULL,
    @p41 varchar(10) = NULL,
    @p42 varchar(10) = NULL,
    @p43 nvarchar(50) = NULL,
    @p44 int = NULL,
    @p45 nvarchar(50) = NULL,
    @p46 int = NULL,
    @p47 varchar(50) = NULL,
    @p48 nvarchar(max) = NULL,
    @p49 nvarchar(50) = NULL,
    @p50 nvarchar(50) = NULL,
    @p51 nvarchar(50) = NULL,
    @p52 uniqueidentifier = NULL,
    @rowguid5 uniqueidentifier = NULL,
    @generation5 bigint = NULL,
    @lineage5 varbinary(311) = NULL,
    @colv5 varbinary(1) = NULL,
    @p53 varchar(10) = NULL,
    @p54 varchar(10) = NULL,
    @p55 varchar(10) = NULL,
    @p56 nvarchar(50) = NULL,
    @p57 int = NULL,
    @p58 nvarchar(50) = NULL,
    @p59 int = NULL,
    @p60 varchar(50) = NULL,
    @p61 nvarchar(max) = NULL,
    @p62 nvarchar(50) = NULL,
    @p63 nvarchar(50) = NULL,
    @p64 nvarchar(50) = NULL,
    @p65 uniqueidentifier = NULL,
    @rowguid6 uniqueidentifier = NULL,
    @generation6 bigint = NULL,
    @lineage6 varbinary(311) = NULL,
    @colv6 varbinary(1) = NULL,
    @p66 varchar(10) = NULL,
    @p67 varchar(10) = NULL,
    @p68 varchar(10) = NULL,
    @p69 nvarchar(50) = NULL,
    @p70 int = NULL,
    @p71 nvarchar(50) = NULL,
    @p72 int = NULL,
    @p73 varchar(50) = NULL,
    @p74 nvarchar(max) = NULL,
    @p75 nvarchar(50) = NULL,
    @p76 nvarchar(50) = NULL,
    @p77 nvarchar(50) = NULL,
    @p78 uniqueidentifier = NULL,
    @rowguid7 uniqueidentifier = NULL,
    @generation7 bigint = NULL,
    @lineage7 varbinary(311) = NULL,
    @colv7 varbinary(1) = NULL,
    @p79 varchar(10) = NULL,
    @p80 varchar(10) = NULL,
    @p81 varchar(10) = NULL,
    @p82 nvarchar(50) = NULL,
    @p83 int = NULL,
    @p84 nvarchar(50) = NULL,
    @p85 int = NULL,
    @p86 varchar(50) = NULL,
    @p87 nvarchar(max) = NULL,
    @p88 nvarchar(50) = NULL,
    @p89 nvarchar(50) = NULL,
    @p90 nvarchar(50) = NULL,
    @p91 uniqueidentifier = NULL,
    @rowguid8 uniqueidentifier = NULL,
    @generation8 bigint = NULL,
    @lineage8 varbinary(311) = NULL,
    @colv8 varbinary(1) = NULL,
    @p92 varchar(10) = NULL
,
    @p93 varchar(10) = NULL,
    @p94 varchar(10) = NULL,
    @p95 nvarchar(50) = NULL,
    @p96 int = NULL,
    @p97 nvarchar(50) = NULL,
    @p98 int = NULL,
    @p99 varchar(50) = NULL,
    @p100 nvarchar(max) = NULL,
    @p101 nvarchar(50) = NULL,
    @p102 nvarchar(50) = NULL,
    @p103 nvarchar(50) = NULL,
    @p104 uniqueidentifier = NULL,
    @rowguid9 uniqueidentifier = NULL,
    @generation9 bigint = NULL,
    @lineage9 varbinary(311) = NULL,
    @colv9 varbinary(1) = NULL,
    @p105 varchar(10) = NULL,
    @p106 varchar(10) = NULL,
    @p107 varchar(10) = NULL,
    @p108 nvarchar(50) = NULL,
    @p109 int = NULL,
    @p110 nvarchar(50) = NULL,
    @p111 int = NULL,
    @p112 varchar(50) = NULL,
    @p113 nvarchar(max) = NULL,
    @p114 nvarchar(50) = NULL,
    @p115 nvarchar(50) = NULL,
    @p116 nvarchar(50) = NULL,
    @p117 uniqueidentifier = NULL,
    @rowguid10 uniqueidentifier = NULL,
    @generation10 bigint = NULL,
    @lineage10 varbinary(311) = NULL,
    @colv10 varbinary(1) = NULL,
    @p118 varchar(10) = NULL,
    @p119 varchar(10) = NULL,
    @p120 varchar(10) = NULL,
    @p121 nvarchar(50) = NULL,
    @p122 int = NULL,
    @p123 nvarchar(50) = NULL,
    @p124 int = NULL,
    @p125 varchar(50) = NULL,
    @p126 nvarchar(max) = NULL,
    @p127 nvarchar(50) = NULL,
    @p128 nvarchar(50) = NULL,
    @p129 nvarchar(50) = NULL,
    @p130 uniqueidentifier = NULL,
    @rowguid11 uniqueidentifier = NULL,
    @generation11 bigint = NULL,
    @lineage11 varbinary(311) = NULL,
    @colv11 varbinary(1) = NULL,
    @p131 varchar(10) = NULL,
    @p132 varchar(10) = NULL,
    @p133 varchar(10) = NULL,
    @p134 nvarchar(50) = NULL,
    @p135 int = NULL,
    @p136 nvarchar(50) = NULL,
    @p137 int = NULL,
    @p138 varchar(50) = NULL,
    @p139 nvarchar(max) = NULL,
    @p140 nvarchar(50) = NULL,
    @p141 nvarchar(50) = NULL,
    @p142 nvarchar(50) = NULL,
    @p143 uniqueidentifier = NULL,
    @rowguid12 uniqueidentifier = NULL,
    @generation12 bigint = NULL,
    @lineage12 varbinary(311) = NULL,
    @colv12 varbinary(1) = NULL,
    @p144 varchar(10) = NULL,
    @p145 varchar(10) = NULL,
    @p146 varchar(10) = NULL,
    @p147 nvarchar(50) = NULL,
    @p148 int = NULL,
    @p149 nvarchar(50) = NULL,
    @p150 int = NULL,
    @p151 varchar(50) = NULL,
    @p152 nvarchar(max) = NULL,
    @p153 nvarchar(50) = NULL,
    @p154 nvarchar(50) = NULL,
    @p155 nvarchar(50) = NULL,
    @p156 uniqueidentifier = NULL,
    @rowguid13 uniqueidentifier = NULL,
    @generation13 bigint = NULL,
    @lineage13 varbinary(311) = NULL,
    @colv13 varbinary(1) = NULL,
    @p157 varchar(10) = NULL,
    @p158 varchar(10) = NULL,
    @p159 varchar(10) = NULL,
    @p160 nvarchar(50) = NULL,
    @p161 int = NULL,
    @p162 nvarchar(50) = NULL,
    @p163 int = NULL,
    @p164 varchar(50) = NULL,
    @p165 nvarchar(max) = NULL,
    @p166 nvarchar(50) = NULL,
    @p167 nvarchar(50) = NULL,
    @p168 nvarchar(50) = NULL,
    @p169 uniqueidentifier = NULL,
    @rowguid14 uniqueidentifier = NULL,
    @generation14 bigint = NULL,
    @lineage14 varbinary(311) = NULL,
    @colv14 varbinary(1) = NULL,
    @p170 varchar(10) = NULL,
    @p171 varchar(10) = NULL,
    @p172 varchar(10) = NULL,
    @p173 nvarchar(50) = NULL,
    @p174 int = NULL,
    @p175 nvarchar(50) = NULL,
    @p176 int = NULL,
    @p177 varchar(50) = NULL,
    @p178 nvarchar(max) = NULL,
    @p179 nvarchar(50) = NULL,
    @p180 nvarchar(50) = NULL,
    @p181 nvarchar(50) = NULL,
    @p182 uniqueidentifier = NULL,
    @rowguid15 uniqueidentifier = NULL,
    @generation15 bigint = NULL,
    @lineage15 varbinary(311) = NULL,
    @colv15 varbinary(1) = NULL,
    @p183 varchar(10) = NULL
,
    @p184 varchar(10) = NULL,
    @p185 varchar(10) = NULL,
    @p186 nvarchar(50) = NULL,
    @p187 int = NULL,
    @p188 nvarchar(50) = NULL,
    @p189 int = NULL,
    @p190 varchar(50) = NULL,
    @p191 nvarchar(max) = NULL,
    @p192 nvarchar(50) = NULL,
    @p193 nvarchar(50) = NULL,
    @p194 nvarchar(50) = NULL,
    @p195 uniqueidentifier = NULL,
    @rowguid16 uniqueidentifier = NULL,
    @generation16 bigint = NULL,
    @lineage16 varbinary(311) = NULL,
    @colv16 varbinary(1) = NULL,
    @p196 varchar(10) = NULL,
    @p197 varchar(10) = NULL,
    @p198 varchar(10) = NULL,
    @p199 nvarchar(50) = NULL,
    @p200 int = NULL,
    @p201 nvarchar(50) = NULL,
    @p202 int = NULL,
    @p203 varchar(50) = NULL,
    @p204 nvarchar(max) = NULL,
    @p205 nvarchar(50) = NULL,
    @p206 nvarchar(50) = NULL,
    @p207 nvarchar(50) = NULL,
    @p208 uniqueidentifier = NULL,
    @rowguid17 uniqueidentifier = NULL,
    @generation17 bigint = NULL,
    @lineage17 varbinary(311) = NULL,
    @colv17 varbinary(1) = NULL,
    @p209 varchar(10) = NULL,
    @p210 varchar(10) = NULL,
    @p211 varchar(10) = NULL,
    @p212 nvarchar(50) = NULL,
    @p213 int = NULL,
    @p214 nvarchar(50) = NULL,
    @p215 int = NULL,
    @p216 varchar(50) = NULL,
    @p217 nvarchar(max) = NULL,
    @p218 nvarchar(50) = NULL,
    @p219 nvarchar(50) = NULL,
    @p220 nvarchar(50) = NULL,
    @p221 uniqueidentifier = NULL,
    @rowguid18 uniqueidentifier = NULL,
    @generation18 bigint = NULL,
    @lineage18 varbinary(311) = NULL,
    @colv18 varbinary(1) = NULL,
    @p222 varchar(10) = NULL,
    @p223 varchar(10) = NULL,
    @p224 varchar(10) = NULL,
    @p225 nvarchar(50) = NULL,
    @p226 int = NULL,
    @p227 nvarchar(50) = NULL,
    @p228 int = NULL,
    @p229 varchar(50) = NULL,
    @p230 nvarchar(max) = NULL,
    @p231 nvarchar(50) = NULL,
    @p232 nvarchar(50) = NULL,
    @p233 nvarchar(50) = NULL,
    @p234 uniqueidentifier = NULL,
    @rowguid19 uniqueidentifier = NULL,
    @generation19 bigint = NULL,
    @lineage19 varbinary(311) = NULL,
    @colv19 varbinary(1) = NULL,
    @p235 varchar(10) = NULL,
    @p236 varchar(10) = NULL,
    @p237 varchar(10) = NULL,
    @p238 nvarchar(50) = NULL,
    @p239 int = NULL,
    @p240 nvarchar(50) = NULL,
    @p241 int = NULL,
    @p242 varchar(50) = NULL,
    @p243 nvarchar(max) = NULL,
    @p244 nvarchar(50) = NULL,
    @p245 nvarchar(50) = NULL,
    @p246 nvarchar(50) = NULL,
    @p247 uniqueidentifier = NULL,
    @rowguid20 uniqueidentifier = NULL,
    @generation20 bigint = NULL,
    @lineage20 varbinary(311) = NULL,
    @colv20 varbinary(1) = NULL,
    @p248 varchar(10) = NULL,
    @p249 varchar(10) = NULL,
    @p250 varchar(10) = NULL,
    @p251 nvarchar(50) = NULL,
    @p252 int = NULL,
    @p253 nvarchar(50) = NULL,
    @p254 int = NULL,
    @p255 varchar(50) = NULL,
    @p256 nvarchar(max) = NULL,
    @p257 nvarchar(50) = NULL,
    @p258 nvarchar(50) = NULL,
    @p259 nvarchar(50) = NULL,
    @p260 uniqueidentifier = NULL,
    @rowguid21 uniqueidentifier = NULL,
    @generation21 bigint = NULL,
    @lineage21 varbinary(311) = NULL,
    @colv21 varbinary(1) = NULL,
    @p261 varchar(10) = NULL,
    @p262 varchar(10) = NULL,
    @p263 varchar(10) = NULL,
    @p264 nvarchar(50) = NULL,
    @p265 int = NULL,
    @p266 nvarchar(50) = NULL,
    @p267 int = NULL,
    @p268 varchar(50) = NULL,
    @p269 nvarchar(max) = NULL,
    @p270 nvarchar(50) = NULL,
    @p271 nvarchar(50) = NULL,
    @p272 nvarchar(50) = NULL,
    @p273 uniqueidentifier = NULL,
    @rowguid22 uniqueidentifier = NULL,
    @generation22 bigint = NULL,
    @lineage22 varbinary(311) = NULL,
    @colv22 varbinary(1) = NULL,
    @p274 varchar(10) = NULL
,
    @p275 varchar(10) = NULL,
    @p276 varchar(10) = NULL,
    @p277 nvarchar(50) = NULL,
    @p278 int = NULL,
    @p279 nvarchar(50) = NULL,
    @p280 int = NULL,
    @p281 varchar(50) = NULL,
    @p282 nvarchar(max) = NULL,
    @p283 nvarchar(50) = NULL,
    @p284 nvarchar(50) = NULL,
    @p285 nvarchar(50) = NULL,
    @p286 uniqueidentifier = NULL,
    @rowguid23 uniqueidentifier = NULL,
    @generation23 bigint = NULL,
    @lineage23 varbinary(311) = NULL,
    @colv23 varbinary(1) = NULL,
    @p287 varchar(10) = NULL,
    @p288 varchar(10) = NULL,
    @p289 varchar(10) = NULL,
    @p290 nvarchar(50) = NULL,
    @p291 int = NULL,
    @p292 nvarchar(50) = NULL,
    @p293 int = NULL,
    @p294 varchar(50) = NULL,
    @p295 nvarchar(max) = NULL,
    @p296 nvarchar(50) = NULL,
    @p297 nvarchar(50) = NULL,
    @p298 nvarchar(50) = NULL,
    @p299 uniqueidentifier = NULL,
    @rowguid24 uniqueidentifier = NULL,
    @generation24 bigint = NULL,
    @lineage24 varbinary(311) = NULL,
    @colv24 varbinary(1) = NULL,
    @p300 varchar(10) = NULL,
    @p301 varchar(10) = NULL,
    @p302 varchar(10) = NULL,
    @p303 nvarchar(50) = NULL,
    @p304 int = NULL,
    @p305 nvarchar(50) = NULL,
    @p306 int = NULL,
    @p307 varchar(50) = NULL,
    @p308 nvarchar(max) = NULL,
    @p309 nvarchar(50) = NULL,
    @p310 nvarchar(50) = NULL,
    @p311 nvarchar(50) = NULL,
    @p312 uniqueidentifier = NULL,
    @rowguid25 uniqueidentifier = NULL,
    @generation25 bigint = NULL,
    @lineage25 varbinary(311) = NULL,
    @colv25 varbinary(1) = NULL,
    @p313 varchar(10) = NULL,
    @p314 varchar(10) = NULL,
    @p315 varchar(10) = NULL,
    @p316 nvarchar(50) = NULL,
    @p317 int = NULL,
    @p318 nvarchar(50) = NULL,
    @p319 int = NULL,
    @p320 varchar(50) = NULL,
    @p321 nvarchar(max) = NULL,
    @p322 nvarchar(50) = NULL,
    @p323 nvarchar(50) = NULL,
    @p324 nvarchar(50) = NULL,
    @p325 uniqueidentifier = NULL,
    @rowguid26 uniqueidentifier = NULL,
    @generation26 bigint = NULL,
    @lineage26 varbinary(311) = NULL,
    @colv26 varbinary(1) = NULL,
    @p326 varchar(10) = NULL,
    @p327 varchar(10) = NULL,
    @p328 varchar(10) = NULL,
    @p329 nvarchar(50) = NULL,
    @p330 int = NULL,
    @p331 nvarchar(50) = NULL,
    @p332 int = NULL,
    @p333 varchar(50) = NULL,
    @p334 nvarchar(max) = NULL,
    @p335 nvarchar(50) = NULL,
    @p336 nvarchar(50) = NULL,
    @p337 nvarchar(50) = NULL,
    @p338 uniqueidentifier = NULL,
    @rowguid27 uniqueidentifier = NULL,
    @generation27 bigint = NULL,
    @lineage27 varbinary(311) = NULL,
    @colv27 varbinary(1) = NULL,
    @p339 varchar(10) = NULL,
    @p340 varchar(10) = NULL,
    @p341 varchar(10) = NULL,
    @p342 nvarchar(50) = NULL,
    @p343 int = NULL,
    @p344 nvarchar(50) = NULL,
    @p345 int = NULL,
    @p346 varchar(50) = NULL,
    @p347 nvarchar(max) = NULL,
    @p348 nvarchar(50) = NULL,
    @p349 nvarchar(50) = NULL,
    @p350 nvarchar(50) = NULL,
    @p351 uniqueidentifier = NULL,
    @rowguid28 uniqueidentifier = NULL,
    @generation28 bigint = NULL,
    @lineage28 varbinary(311) = NULL,
    @colv28 varbinary(1) = NULL,
    @p352 varchar(10) = NULL,
    @p353 varchar(10) = NULL,
    @p354 varchar(10) = NULL,
    @p355 nvarchar(50) = NULL,
    @p356 int = NULL,
    @p357 nvarchar(50) = NULL,
    @p358 int = NULL,
    @p359 varchar(50) = NULL,
    @p360 nvarchar(max) = NULL,
    @p361 nvarchar(50) = NULL,
    @p362 nvarchar(50) = NULL,
    @p363 nvarchar(50) = NULL,
    @p364 uniqueidentifier = NULL,
    @rowguid29 uniqueidentifier = NULL,
    @generation29 bigint = NULL,
    @lineage29 varbinary(311) = NULL,
    @colv29 varbinary(1) = NULL,
    @p365 varchar(10) = NULL
,
    @p366 varchar(10) = NULL,
    @p367 varchar(10) = NULL,
    @p368 nvarchar(50) = NULL,
    @p369 int = NULL,
    @p370 nvarchar(50) = NULL,
    @p371 int = NULL,
    @p372 varchar(50) = NULL,
    @p373 nvarchar(max) = NULL,
    @p374 nvarchar(50) = NULL,
    @p375 nvarchar(50) = NULL,
    @p376 nvarchar(50) = NULL,
    @p377 uniqueidentifier = NULL,
    @rowguid30 uniqueidentifier = NULL,
    @generation30 bigint = NULL,
    @lineage30 varbinary(311) = NULL,
    @colv30 varbinary(1) = NULL,
    @p378 varchar(10) = NULL,
    @p379 varchar(10) = NULL,
    @p380 varchar(10) = NULL,
    @p381 nvarchar(50) = NULL,
    @p382 int = NULL,
    @p383 nvarchar(50) = NULL,
    @p384 int = NULL,
    @p385 varchar(50) = NULL,
    @p386 nvarchar(max) = NULL,
    @p387 nvarchar(50) = NULL,
    @p388 nvarchar(50) = NULL,
    @p389 nvarchar(50) = NULL,
    @p390 uniqueidentifier = NULL,
    @rowguid31 uniqueidentifier = NULL,
    @generation31 bigint = NULL,
    @lineage31 varbinary(311) = NULL,
    @colv31 varbinary(1) = NULL,
    @p391 varchar(10) = NULL,
    @p392 varchar(10) = NULL,
    @p393 varchar(10) = NULL,
    @p394 nvarchar(50) = NULL,
    @p395 int = NULL,
    @p396 nvarchar(50) = NULL,
    @p397 int = NULL,
    @p398 varchar(50) = NULL,
    @p399 nvarchar(max) = NULL,
    @p400 nvarchar(50) = NULL,
    @p401 nvarchar(50) = NULL,
    @p402 nvarchar(50) = NULL,
    @p403 uniqueidentifier = NULL,
    @rowguid32 uniqueidentifier = NULL,
    @generation32 bigint = NULL,
    @lineage32 varbinary(311) = NULL,
    @colv32 varbinary(1) = NULL,
    @p404 varchar(10) = NULL,
    @p405 varchar(10) = NULL,
    @p406 varchar(10) = NULL,
    @p407 nvarchar(50) = NULL,
    @p408 int = NULL,
    @p409 nvarchar(50) = NULL,
    @p410 int = NULL,
    @p411 varchar(50) = NULL,
    @p412 nvarchar(max) = NULL,
    @p413 nvarchar(50) = NULL,
    @p414 nvarchar(50) = NULL,
    @p415 nvarchar(50) = NULL,
    @p416 uniqueidentifier = NULL,
    @rowguid33 uniqueidentifier = NULL,
    @generation33 bigint = NULL,
    @lineage33 varbinary(311) = NULL,
    @colv33 varbinary(1) = NULL,
    @p417 varchar(10) = NULL,
    @p418 varchar(10) = NULL,
    @p419 varchar(10) = NULL,
    @p420 nvarchar(50) = NULL,
    @p421 int = NULL,
    @p422 nvarchar(50) = NULL,
    @p423 int = NULL,
    @p424 varchar(50) = NULL,
    @p425 nvarchar(max) = NULL,
    @p426 nvarchar(50) = NULL,
    @p427 nvarchar(50) = NULL,
    @p428 nvarchar(50) = NULL,
    @p429 uniqueidentifier = NULL,
    @rowguid34 uniqueidentifier = NULL,
    @generation34 bigint = NULL,
    @lineage34 varbinary(311) = NULL,
    @colv34 varbinary(1) = NULL,
    @p430 varchar(10) = NULL,
    @p431 varchar(10) = NULL,
    @p432 varchar(10) = NULL,
    @p433 nvarchar(50) = NULL,
    @p434 int = NULL,
    @p435 nvarchar(50) = NULL,
    @p436 int = NULL,
    @p437 varchar(50) = NULL,
    @p438 nvarchar(max) = NULL,
    @p439 nvarchar(50) = NULL,
    @p440 nvarchar(50) = NULL,
    @p441 nvarchar(50) = NULL,
    @p442 uniqueidentifier = NULL,
    @rowguid35 uniqueidentifier = NULL,
    @generation35 bigint = NULL,
    @lineage35 varbinary(311) = NULL,
    @colv35 varbinary(1) = NULL,
    @p443 varchar(10) = NULL,
    @p444 varchar(10) = NULL,
    @p445 varchar(10) = NULL,
    @p446 nvarchar(50) = NULL,
    @p447 int = NULL,
    @p448 nvarchar(50) = NULL,
    @p449 int = NULL,
    @p450 varchar(50) = NULL,
    @p451 nvarchar(max) = NULL,
    @p452 nvarchar(50) = NULL,
    @p453 nvarchar(50) = NULL,
    @p454 nvarchar(50) = NULL,
    @p455 uniqueidentifier = NULL,
    @rowguid36 uniqueidentifier = NULL,
    @generation36 bigint = NULL,
    @lineage36 varbinary(311) = NULL,
    @colv36 varbinary(1) = NULL,
    @p456 varchar(10) = NULL
,
    @p457 varchar(10) = NULL,
    @p458 varchar(10) = NULL,
    @p459 nvarchar(50) = NULL,
    @p460 int = NULL,
    @p461 nvarchar(50) = NULL,
    @p462 int = NULL,
    @p463 varchar(50) = NULL,
    @p464 nvarchar(max) = NULL,
    @p465 nvarchar(50) = NULL,
    @p466 nvarchar(50) = NULL,
    @p467 nvarchar(50) = NULL,
    @p468 uniqueidentifier = NULL,
    @rowguid37 uniqueidentifier = NULL,
    @generation37 bigint = NULL,
    @lineage37 varbinary(311) = NULL,
    @colv37 varbinary(1) = NULL,
    @p469 varchar(10) = NULL,
    @p470 varchar(10) = NULL,
    @p471 varchar(10) = NULL,
    @p472 nvarchar(50) = NULL,
    @p473 int = NULL,
    @p474 nvarchar(50) = NULL,
    @p475 int = NULL,
    @p476 varchar(50) = NULL,
    @p477 nvarchar(max) = NULL,
    @p478 nvarchar(50) = NULL,
    @p479 nvarchar(50) = NULL,
    @p480 nvarchar(50) = NULL,
    @p481 uniqueidentifier = NULL,
    @rowguid38 uniqueidentifier = NULL,
    @generation38 bigint = NULL,
    @lineage38 varbinary(311) = NULL,
    @colv38 varbinary(1) = NULL,
    @p482 varchar(10) = NULL,
    @p483 varchar(10) = NULL,
    @p484 varchar(10) = NULL,
    @p485 nvarchar(50) = NULL,
    @p486 int = NULL,
    @p487 nvarchar(50) = NULL,
    @p488 int = NULL,
    @p489 varchar(50) = NULL,
    @p490 nvarchar(max) = NULL,
    @p491 nvarchar(50) = NULL,
    @p492 nvarchar(50) = NULL,
    @p493 nvarchar(50) = NULL,
    @p494 uniqueidentifier = NULL,
    @rowguid39 uniqueidentifier = NULL,
    @generation39 bigint = NULL,
    @lineage39 varbinary(311) = NULL,
    @colv39 varbinary(1) = NULL,
    @p495 varchar(10) = NULL,
    @p496 varchar(10) = NULL,
    @p497 varchar(10) = NULL,
    @p498 nvarchar(50) = NULL,
    @p499 int = NULL,
    @p500 nvarchar(50) = NULL,
    @p501 int = NULL,
    @p502 varchar(50) = NULL,
    @p503 nvarchar(max) = NULL,
    @p504 nvarchar(50) = NULL,
    @p505 nvarchar(50) = NULL,
    @p506 nvarchar(50) = NULL,
    @p507 uniqueidentifier = NULL,
    @rowguid40 uniqueidentifier = NULL,
    @generation40 bigint = NULL,
    @lineage40 varbinary(311) = NULL,
    @colv40 varbinary(1) = NULL,
    @p508 varchar(10) = NULL,
    @p509 varchar(10) = NULL,
    @p510 varchar(10) = NULL,
    @p511 nvarchar(50) = NULL,
    @p512 int = NULL,
    @p513 nvarchar(50) = NULL,
    @p514 int = NULL,
    @p515 varchar(50) = NULL,
    @p516 nvarchar(max) = NULL,
    @p517 nvarchar(50) = NULL,
    @p518 nvarchar(50) = NULL,
    @p519 nvarchar(50) = NULL,
    @p520 uniqueidentifier = NULL,
    @rowguid41 uniqueidentifier = NULL,
    @generation41 bigint = NULL,
    @lineage41 varbinary(311) = NULL,
    @colv41 varbinary(1) = NULL,
    @p521 varchar(10) = NULL,
    @p522 varchar(10) = NULL,
    @p523 varchar(10) = NULL,
    @p524 nvarchar(50) = NULL,
    @p525 int = NULL,
    @p526 nvarchar(50) = NULL,
    @p527 int = NULL,
    @p528 varchar(50) = NULL,
    @p529 nvarchar(max) = NULL,
    @p530 nvarchar(50) = NULL,
    @p531 nvarchar(50) = NULL,
    @p532 nvarchar(50) = NULL,
    @p533 uniqueidentifier = NULL,
    @rowguid42 uniqueidentifier = NULL,
    @generation42 bigint = NULL,
    @lineage42 varbinary(311) = NULL,
    @colv42 varbinary(1) = NULL,
    @p534 varchar(10) = NULL,
    @p535 varchar(10) = NULL,
    @p536 varchar(10) = NULL,
    @p537 nvarchar(50) = NULL,
    @p538 int = NULL,
    @p539 nvarchar(50) = NULL,
    @p540 int = NULL,
    @p541 varchar(50) = NULL,
    @p542 nvarchar(max) = NULL,
    @p543 nvarchar(50) = NULL,
    @p544 nvarchar(50) = NULL,
    @p545 nvarchar(50) = NULL,
    @p546 uniqueidentifier = NULL,
    @rowguid43 uniqueidentifier = NULL,
    @generation43 bigint = NULL,
    @lineage43 varbinary(311) = NULL,
    @colv43 varbinary(1) = NULL,
    @p547 varchar(10) = NULL
,
    @p548 varchar(10) = NULL,
    @p549 varchar(10) = NULL,
    @p550 nvarchar(50) = NULL,
    @p551 int = NULL,
    @p552 nvarchar(50) = NULL,
    @p553 int = NULL,
    @p554 varchar(50) = NULL,
    @p555 nvarchar(max) = NULL,
    @p556 nvarchar(50) = NULL,
    @p557 nvarchar(50) = NULL,
    @p558 nvarchar(50) = NULL,
    @p559 uniqueidentifier = NULL,
    @rowguid44 uniqueidentifier = NULL,
    @generation44 bigint = NULL,
    @lineage44 varbinary(311) = NULL,
    @colv44 varbinary(1) = NULL,
    @p560 varchar(10) = NULL,
    @p561 varchar(10) = NULL,
    @p562 varchar(10) = NULL,
    @p563 nvarchar(50) = NULL,
    @p564 int = NULL,
    @p565 nvarchar(50) = NULL,
    @p566 int = NULL,
    @p567 varchar(50) = NULL,
    @p568 nvarchar(max) = NULL,
    @p569 nvarchar(50) = NULL,
    @p570 nvarchar(50) = NULL,
    @p571 nvarchar(50) = NULL,
    @p572 uniqueidentifier = NULL,
    @rowguid45 uniqueidentifier = NULL,
    @generation45 bigint = NULL,
    @lineage45 varbinary(311) = NULL,
    @colv45 varbinary(1) = NULL,
    @p573 varchar(10) = NULL,
    @p574 varchar(10) = NULL,
    @p575 varchar(10) = NULL,
    @p576 nvarchar(50) = NULL,
    @p577 int = NULL,
    @p578 nvarchar(50) = NULL,
    @p579 int = NULL,
    @p580 varchar(50) = NULL,
    @p581 nvarchar(max) = NULL,
    @p582 nvarchar(50) = NULL,
    @p583 nvarchar(50) = NULL,
    @p584 nvarchar(50) = NULL,
    @p585 uniqueidentifier = NULL,
    @rowguid46 uniqueidentifier = NULL,
    @generation46 bigint = NULL,
    @lineage46 varbinary(311) = NULL,
    @colv46 varbinary(1) = NULL,
    @p586 varchar(10) = NULL,
    @p587 varchar(10) = NULL,
    @p588 varchar(10) = NULL,
    @p589 nvarchar(50) = NULL,
    @p590 int = NULL,
    @p591 nvarchar(50) = NULL,
    @p592 int = NULL,
    @p593 varchar(50) = NULL,
    @p594 nvarchar(max) = NULL,
    @p595 nvarchar(50) = NULL,
    @p596 nvarchar(50) = NULL,
    @p597 nvarchar(50) = NULL,
    @p598 uniqueidentifier = NULL,
    @rowguid47 uniqueidentifier = NULL,
    @generation47 bigint = NULL,
    @lineage47 varbinary(311) = NULL,
    @colv47 varbinary(1) = NULL,
    @p599 varchar(10) = NULL,
    @p600 varchar(10) = NULL,
    @p601 varchar(10) = NULL,
    @p602 nvarchar(50) = NULL,
    @p603 int = NULL,
    @p604 nvarchar(50) = NULL,
    @p605 int = NULL,
    @p606 varchar(50) = NULL,
    @p607 nvarchar(max) = NULL,
    @p608 nvarchar(50) = NULL,
    @p609 nvarchar(50) = NULL,
    @p610 nvarchar(50) = NULL,
    @p611 uniqueidentifier = NULL,
    @rowguid48 uniqueidentifier = NULL,
    @generation48 bigint = NULL,
    @lineage48 varbinary(311) = NULL,
    @colv48 varbinary(1) = NULL,
    @p612 varchar(10) = NULL,
    @p613 varchar(10) = NULL,
    @p614 varchar(10) = NULL,
    @p615 nvarchar(50) = NULL,
    @p616 int = NULL,
    @p617 nvarchar(50) = NULL,
    @p618 int = NULL,
    @p619 varchar(50) = NULL,
    @p620 nvarchar(max) = NULL,
    @p621 nvarchar(50) = NULL,
    @p622 nvarchar(50) = NULL,
    @p623 nvarchar(50) = NULL,
    @p624 uniqueidentifier = NULL,
    @rowguid49 uniqueidentifier = NULL,
    @generation49 bigint = NULL,
    @lineage49 varbinary(311) = NULL,
    @colv49 varbinary(1) = NULL,
    @p625 varchar(10) = NULL,
    @p626 varchar(10) = NULL,
    @p627 varchar(10) = NULL,
    @p628 nvarchar(50) = NULL,
    @p629 int = NULL,
    @p630 nvarchar(50) = NULL,
    @p631 int = NULL,
    @p632 varchar(50) = NULL,
    @p633 nvarchar(max) = NULL,
    @p634 nvarchar(50) = NULL,
    @p635 nvarchar(50) = NULL,
    @p636 nvarchar(50) = NULL,
    @p637 uniqueidentifier = NULL,
    @rowguid50 uniqueidentifier = NULL,
    @generation50 bigint = NULL,
    @lineage50 varbinary(311) = NULL,
    @colv50 varbinary(1) = NULL,
    @p638 varchar(10) = NULL
,
    @p639 varchar(10) = NULL,
    @p640 varchar(10) = NULL,
    @p641 nvarchar(50) = NULL,
    @p642 int = NULL,
    @p643 nvarchar(50) = NULL,
    @p644 int = NULL,
    @p645 varchar(50) = NULL,
    @p646 nvarchar(max) = NULL,
    @p647 nvarchar(50) = NULL,
    @p648 nvarchar(50) = NULL,
    @p649 nvarchar(50) = NULL,
    @p650 uniqueidentifier = NULL,
    @rowguid51 uniqueidentifier = NULL,
    @generation51 bigint = NULL,
    @lineage51 varbinary(311) = NULL,
    @colv51 varbinary(1) = NULL,
    @p651 varchar(10) = NULL,
    @p652 varchar(10) = NULL,
    @p653 varchar(10) = NULL,
    @p654 nvarchar(50) = NULL,
    @p655 int = NULL,
    @p656 nvarchar(50) = NULL,
    @p657 int = NULL,
    @p658 varchar(50) = NULL,
    @p659 nvarchar(max) = NULL,
    @p660 nvarchar(50) = NULL,
    @p661 nvarchar(50) = NULL,
    @p662 nvarchar(50) = NULL,
    @p663 uniqueidentifier = NULL,
    @rowguid52 uniqueidentifier = NULL,
    @generation52 bigint = NULL,
    @lineage52 varbinary(311) = NULL,
    @colv52 varbinary(1) = NULL,
    @p664 varchar(10) = NULL,
    @p665 varchar(10) = NULL,
    @p666 varchar(10) = NULL,
    @p667 nvarchar(50) = NULL,
    @p668 int = NULL,
    @p669 nvarchar(50) = NULL,
    @p670 int = NULL,
    @p671 varchar(50) = NULL,
    @p672 nvarchar(max) = NULL,
    @p673 nvarchar(50) = NULL,
    @p674 nvarchar(50) = NULL,
    @p675 nvarchar(50) = NULL,
    @p676 uniqueidentifier = NULL,
    @rowguid53 uniqueidentifier = NULL,
    @generation53 bigint = NULL,
    @lineage53 varbinary(311) = NULL,
    @colv53 varbinary(1) = NULL,
    @p677 varchar(10) = NULL,
    @p678 varchar(10) = NULL,
    @p679 varchar(10) = NULL,
    @p680 nvarchar(50) = NULL,
    @p681 int = NULL,
    @p682 nvarchar(50) = NULL,
    @p683 int = NULL,
    @p684 varchar(50) = NULL,
    @p685 nvarchar(max) = NULL,
    @p686 nvarchar(50) = NULL,
    @p687 nvarchar(50) = NULL,
    @p688 nvarchar(50) = NULL,
    @p689 uniqueidentifier = NULL,
    @rowguid54 uniqueidentifier = NULL,
    @generation54 bigint = NULL,
    @lineage54 varbinary(311) = NULL,
    @colv54 varbinary(1) = NULL,
    @p690 varchar(10) = NULL,
    @p691 varchar(10) = NULL,
    @p692 varchar(10) = NULL,
    @p693 nvarchar(50) = NULL,
    @p694 int = NULL,
    @p695 nvarchar(50) = NULL,
    @p696 int = NULL,
    @p697 varchar(50) = NULL,
    @p698 nvarchar(max) = NULL,
    @p699 nvarchar(50) = NULL,
    @p700 nvarchar(50) = NULL,
    @p701 nvarchar(50) = NULL,
    @p702 uniqueidentifier = NULL,
    @rowguid55 uniqueidentifier = NULL,
    @generation55 bigint = NULL,
    @lineage55 varbinary(311) = NULL,
    @colv55 varbinary(1) = NULL,
    @p703 varchar(10) = NULL,
    @p704 varchar(10) = NULL,
    @p705 varchar(10) = NULL,
    @p706 nvarchar(50) = NULL,
    @p707 int = NULL,
    @p708 nvarchar(50) = NULL,
    @p709 int = NULL,
    @p710 varchar(50) = NULL,
    @p711 nvarchar(max) = NULL,
    @p712 nvarchar(50) = NULL,
    @p713 nvarchar(50) = NULL,
    @p714 nvarchar(50) = NULL,
    @p715 uniqueidentifier = NULL,
    @rowguid56 uniqueidentifier = NULL,
    @generation56 bigint = NULL,
    @lineage56 varbinary(311) = NULL,
    @colv56 varbinary(1) = NULL,
    @p716 varchar(10) = NULL,
    @p717 varchar(10) = NULL,
    @p718 varchar(10) = NULL,
    @p719 nvarchar(50) = NULL,
    @p720 int = NULL,
    @p721 nvarchar(50) = NULL,
    @p722 int = NULL,
    @p723 varchar(50) = NULL,
    @p724 nvarchar(max) = NULL,
    @p725 nvarchar(50) = NULL,
    @p726 nvarchar(50) = NULL,
    @p727 nvarchar(50) = NULL,
    @p728 uniqueidentifier = NULL,
    @rowguid57 uniqueidentifier = NULL,
    @generation57 bigint = NULL,
    @lineage57 varbinary(311) = NULL,
    @colv57 varbinary(1) = NULL,
    @p729 varchar(10) = NULL
,
    @p730 varchar(10) = NULL,
    @p731 varchar(10) = NULL,
    @p732 nvarchar(50) = NULL,
    @p733 int = NULL,
    @p734 nvarchar(50) = NULL,
    @p735 int = NULL,
    @p736 varchar(50) = NULL,
    @p737 nvarchar(max) = NULL,
    @p738 nvarchar(50) = NULL,
    @p739 nvarchar(50) = NULL,
    @p740 nvarchar(50) = NULL,
    @p741 uniqueidentifier = NULL,
    @rowguid58 uniqueidentifier = NULL,
    @generation58 bigint = NULL,
    @lineage58 varbinary(311) = NULL,
    @colv58 varbinary(1) = NULL,
    @p742 varchar(10) = NULL,
    @p743 varchar(10) = NULL,
    @p744 varchar(10) = NULL,
    @p745 nvarchar(50) = NULL,
    @p746 int = NULL,
    @p747 nvarchar(50) = NULL,
    @p748 int = NULL,
    @p749 varchar(50) = NULL,
    @p750 nvarchar(max) = NULL,
    @p751 nvarchar(50) = NULL,
    @p752 nvarchar(50) = NULL,
    @p753 nvarchar(50) = NULL,
    @p754 uniqueidentifier = NULL,
    @rowguid59 uniqueidentifier = NULL,
    @generation59 bigint = NULL,
    @lineage59 varbinary(311) = NULL,
    @colv59 varbinary(1) = NULL,
    @p755 varchar(10) = NULL,
    @p756 varchar(10) = NULL,
    @p757 varchar(10) = NULL,
    @p758 nvarchar(50) = NULL,
    @p759 int = NULL,
    @p760 nvarchar(50) = NULL,
    @p761 int = NULL,
    @p762 varchar(50) = NULL,
    @p763 nvarchar(max) = NULL,
    @p764 nvarchar(50) = NULL,
    @p765 nvarchar(50) = NULL,
    @p766 nvarchar(50) = NULL,
    @p767 uniqueidentifier = NULL,
    @rowguid60 uniqueidentifier = NULL,
    @generation60 bigint = NULL,
    @lineage60 varbinary(311) = NULL,
    @colv60 varbinary(1) = NULL,
    @p768 varchar(10) = NULL
,
    @p769 varchar(10) = NULL
,
    @p770 varchar(10) = NULL
,
    @p771 nvarchar(50) = NULL
,
    @p772 int = NULL
,
    @p773 nvarchar(50) = NULL
,
    @p774 int = NULL
,
    @p775 varchar(50) = NULL
,
    @p776 nvarchar(max) = NULL
,
    @p777 nvarchar(50) = NULL
,
    @p778 nvarchar(50) = NULL
,
    @p779 nvarchar(50) = NULL
,
    @p780 uniqueidentifier = NULL

) as
begin
    declare @errcode    int
    declare @retcode    int
    declare @rowcount   int
    declare @error      int
    declare @rows_in_contents int
    declare @rows_inserted_into_contents int
    declare @publication_number smallint
    declare @gen_cur bigint
    declare @rows_in_tomb bit
    declare @rows_in_syncview int
    declare @marker uniqueidentifier
    
    set nocount on
    
    set @errcode= 0
    set @publication_number = 3
    
    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin
        RAISERROR (14126, 11, -1)
        return 4
    end

    if @rows_tobe_inserted is NULL or @rows_tobe_inserted <=0
        return 0



    begin tran
    save tran batchinsertproc 

    exec @retcode = sys.sp_MSmerge_getgencur_public 49871000, @rows_tobe_inserted, @gen_cur output
    if @retcode<>0 or @@error<>0
        return 4



    select @rows_in_tomb = 0
    select @rows_in_tomb = 1 from (

         select @rowguid1 as rowguid
 union all 
         select @rowguid2 as rowguid
 union all 
         select @rowguid3 as rowguid
 union all 
         select @rowguid4 as rowguid
 union all 
         select @rowguid5 as rowguid
 union all 
         select @rowguid6 as rowguid
 union all 
         select @rowguid7 as rowguid
 union all 
         select @rowguid8 as rowguid
 union all 
         select @rowguid9 as rowguid
 union all 
         select @rowguid10 as rowguid
 union all 
         select @rowguid11 as rowguid
 union all 
         select @rowguid12 as rowguid
 union all 
         select @rowguid13 as rowguid
 union all 
         select @rowguid14 as rowguid
 union all 
         select @rowguid15 as rowguid
 union all 
         select @rowguid16 as rowguid
 union all 
         select @rowguid17 as rowguid
 union all 
         select @rowguid18 as rowguid
 union all 
         select @rowguid19 as rowguid
 union all 
         select @rowguid20 as rowguid
 union all 
         select @rowguid21 as rowguid
 union all 
         select @rowguid22 as rowguid
 union all 
         select @rowguid23 as rowguid
 union all 
         select @rowguid24 as rowguid
 union all 
         select @rowguid25 as rowguid
 union all 
         select @rowguid26 as rowguid
 union all 
         select @rowguid27 as rowguid
 union all 
         select @rowguid28 as rowguid
 union all 
         select @rowguid29 as rowguid
 union all 
         select @rowguid30 as rowguid
 union all 
         select @rowguid31 as rowguid
 union all 
         select @rowguid32 as rowguid
 union all 
         select @rowguid33 as rowguid
 union all 
         select @rowguid34 as rowguid
 union all 
         select @rowguid35 as rowguid
 union all 
         select @rowguid36 as rowguid
 union all 
         select @rowguid37 as rowguid
 union all 
         select @rowguid38 as rowguid
 union all 
         select @rowguid39 as rowguid
 union all 
         select @rowguid40 as rowguid
 union all 
         select @rowguid41 as rowguid
 union all 
         select @rowguid42 as rowguid
 union all 
         select @rowguid43 as rowguid
 union all 
         select @rowguid44 as rowguid
 union all 
         select @rowguid45 as rowguid
 union all 
         select @rowguid46 as rowguid
 union all 
         select @rowguid47 as rowguid
 union all 
         select @rowguid48 as rowguid
 union all 
         select @rowguid49 as rowguid
 union all 
         select @rowguid50 as rowguid
 union all 
         select @rowguid51 as rowguid
 union all 
         select @rowguid52 as rowguid
 union all 
         select @rowguid53 as rowguid
 union all 
         select @rowguid54 as rowguid
 union all 
         select @rowguid55 as rowguid
 union all 
         select @rowguid56 as rowguid
 union all 
         select @rowguid57 as rowguid
 union all 
         select @rowguid58 as rowguid
 union all 
         select @rowguid59 as rowguid
 union all 
         select @rowguid60 as rowguid

    ) as rows
    inner join dbo.MSmerge_tombstone tomb with (rowlock) 
    on tomb.rowguid = rows.rowguid
    and tomb.tablenick = 49871000
    and rows.rowguid is not NULL
        
    if @rows_in_tomb = 1
    begin
        raiserror(20692, 16, -1, 'SANPHAM')
        set @errcode=3
        goto Failure
    end

    
    select @marker = newid()
    insert into dbo.MSmerge_contents with (rowlock)
    (rowguid, tablenick, generation, partchangegen, lineage, colv1, marker)
    select rows.rowguid, 49871000, rows.generation, (-rows.generation), rows.lineage, rows.colv, @marker
    from (

    select @rowguid1 as rowguid, @generation1 as generation, @lineage1 as lineage, @colv1 as colv union all
    select @rowguid2 as rowguid, @generation2 as generation, @lineage2 as lineage, @colv2 as colv union all
    select @rowguid3 as rowguid, @generation3 as generation, @lineage3 as lineage, @colv3 as colv union all
    select @rowguid4 as rowguid, @generation4 as generation, @lineage4 as lineage, @colv4 as colv union all
    select @rowguid5 as rowguid, @generation5 as generation, @lineage5 as lineage, @colv5 as colv union all
    select @rowguid6 as rowguid, @generation6 as generation, @lineage6 as lineage, @colv6 as colv union all
    select @rowguid7 as rowguid, @generation7 as generation, @lineage7 as lineage, @colv7 as colv union all
    select @rowguid8 as rowguid, @generation8 as generation, @lineage8 as lineage, @colv8 as colv union all
    select @rowguid9 as rowguid, @generation9 as generation, @lineage9 as lineage, @colv9 as colv union all
    select @rowguid10 as rowguid, @generation10 as generation, @lineage10 as lineage, @colv10 as colv union all
    select @rowguid11 as rowguid, @generation11 as generation, @lineage11 as lineage, @colv11 as colv union all
    select @rowguid12 as rowguid, @generation12 as generation, @lineage12 as lineage, @colv12 as colv union all
    select @rowguid13 as rowguid, @generation13 as generation, @lineage13 as lineage, @colv13 as colv union all
    select @rowguid14 as rowguid, @generation14 as generation, @lineage14 as lineage, @colv14 as colv union all
    select @rowguid15 as rowguid, @generation15 as generation, @lineage15 as lineage, @colv15 as colv union all
    select @rowguid16 as rowguid, @generation16 as generation, @lineage16 as lineage, @colv16 as colv union all
    select @rowguid17 as rowguid, @generation17 as generation, @lineage17 as lineage, @colv17 as colv union all
    select @rowguid18 as rowguid, @generation18 as generation, @lineage18 as lineage, @colv18 as colv union all
    select @rowguid19 as rowguid, @generation19 as generation, @lineage19 as lineage, @colv19 as colv union all
    select @rowguid20 as rowguid, @generation20 as generation, @lineage20 as lineage, @colv20 as colv union all
    select @rowguid21 as rowguid, @generation21 as generation, @lineage21 as lineage, @colv21 as colv union all
    select @rowguid22 as rowguid, @generation22 as generation, @lineage22 as lineage, @colv22 as colv union all
    select @rowguid23 as rowguid, @generation23 as generation, @lineage23 as lineage, @colv23 as colv union all
    select @rowguid24 as rowguid, @generation24 as generation, @lineage24 as lineage, @colv24 as colv union all
    select @rowguid25 as rowguid, @generation25 as generation, @lineage25 as lineage, @colv25 as colv union all
    select @rowguid26 as rowguid, @generation26 as generation, @lineage26 as lineage, @colv26 as colv union all
    select @rowguid27 as rowguid, @generation27 as generation, @lineage27 as lineage, @colv27 as colv union all
    select @rowguid28 as rowguid, @generation28 as generation, @lineage28 as lineage, @colv28 as colv union all
    select @rowguid29 as rowguid, @generation29 as generation, @lineage29 as lineage, @colv29 as colv union all
    select @rowguid30 as rowguid, @generation30 as generation, @lineage30 as lineage, @colv30 as colv union all
    select @rowguid31 as rowguid, @generation31 as generation, @lineage31 as lineage, @colv31 as colv union all
    select @rowguid32 as rowguid, @generation32 as generation, @lineage32 as lineage, @colv32 as colv union all
    select @rowguid33 as rowguid, @generation33 as generation, @lineage33 as lineage, @colv33 as colv union all
    select @rowguid34 as rowguid, @generation34 as generation, @lineage34 as lineage, @colv34 as colv
 union all
    select @rowguid35 as rowguid, @generation35 as generation, @lineage35 as lineage, @colv35 as colv union all
    select @rowguid36 as rowguid, @generation36 as generation, @lineage36 as lineage, @colv36 as colv union all
    select @rowguid37 as rowguid, @generation37 as generation, @lineage37 as lineage, @colv37 as colv union all
    select @rowguid38 as rowguid, @generation38 as generation, @lineage38 as lineage, @colv38 as colv union all
    select @rowguid39 as rowguid, @generation39 as generation, @lineage39 as lineage, @colv39 as colv union all
    select @rowguid40 as rowguid, @generation40 as generation, @lineage40 as lineage, @colv40 as colv union all
    select @rowguid41 as rowguid, @generation41 as generation, @lineage41 as lineage, @colv41 as colv union all
    select @rowguid42 as rowguid, @generation42 as generation, @lineage42 as lineage, @colv42 as colv union all
    select @rowguid43 as rowguid, @generation43 as generation, @lineage43 as lineage, @colv43 as colv union all
    select @rowguid44 as rowguid, @generation44 as generation, @lineage44 as lineage, @colv44 as colv union all
    select @rowguid45 as rowguid, @generation45 as generation, @lineage45 as lineage, @colv45 as colv union all
    select @rowguid46 as rowguid, @generation46 as generation, @lineage46 as lineage, @colv46 as colv union all
    select @rowguid47 as rowguid, @generation47 as generation, @lineage47 as lineage, @colv47 as colv union all
    select @rowguid48 as rowguid, @generation48 as generation, @lineage48 as lineage, @colv48 as colv union all
    select @rowguid49 as rowguid, @generation49 as generation, @lineage49 as lineage, @colv49 as colv union all
    select @rowguid50 as rowguid, @generation50 as generation, @lineage50 as lineage, @colv50 as colv union all
    select @rowguid51 as rowguid, @generation51 as generation, @lineage51 as lineage, @colv51 as colv union all
    select @rowguid52 as rowguid, @generation52 as generation, @lineage52 as lineage, @colv52 as colv union all
    select @rowguid53 as rowguid, @generation53 as generation, @lineage53 as lineage, @colv53 as colv union all
    select @rowguid54 as rowguid, @generation54 as generation, @lineage54 as lineage, @colv54 as colv union all
    select @rowguid55 as rowguid, @generation55 as generation, @lineage55 as lineage, @colv55 as colv union all
    select @rowguid56 as rowguid, @generation56 as generation, @lineage56 as lineage, @colv56 as colv union all
    select @rowguid57 as rowguid, @generation57 as generation, @lineage57 as lineage, @colv57 as colv union all
    select @rowguid58 as rowguid, @generation58 as generation, @lineage58 as lineage, @colv58 as colv union all
    select @rowguid59 as rowguid, @generation59 as generation, @lineage59 as lineage, @colv59 as colv union all
    select @rowguid60 as rowguid, @generation60 as generation, @lineage60 as lineage, @colv60 as colv

    ) as rows
    where rows.rowguid is not NULL 

    select @rows_inserted_into_contents = @@rowcount, @error = @@error
    if @error<>0
    begin
        set @errcode=3
        goto Failure
    end

    if (@rows_inserted_into_contents <> @rows_tobe_inserted)
    begin
        raiserror(20693, 16, -1, 'SANPHAM')
        set @errcode=4
        goto Failure
    end

    insert into [dbo].[SANPHAM] with (rowlock) (
[MASP]
, 
        [MANCC]
, 
        [MALOAI]
, 
        [TENSP]
, 
        [DONGIA]
, 
        [DVT]
, 
        [SOLUONG]
, 
        [ANH]
, 
        [MOTA]
, 
        [KICHTHUOC]
, 
        [TRONGLUONG]
, 
        [MAUSAC]
, 
        [rowguid]
)
    select 
c1
, 
        c2
, 
        c3
, 
        c4
, 
        c5
, 
        c6
, 
        c7
, 
        c8
, 
        c9
, 
        c10
, 
        c11
, 
        c12
, 
        rowguid

    from (

    select @p1 as c1, @p2 as c2, @p3 as c3, @p4 as c4, @p5 as c5, @p6 as c6, @p7 as c7, @p8 as c8, @p9 as c9, 
        @p10 as c10, @p11 as c11, @p12 as c12, @p13 as rowguid union all
    select @p14 as c1, @p15 as c2, @p16 as c3, @p17 as c4, @p18 as c5, @p19 as c6, @p20 as c7, @p21 as c8, @p22 as c9, 
        @p23 as c10, @p24 as c11, @p25 as c12, @p26 as rowguid union all
    select @p27 as c1, @p28 as c2, @p29 as c3, @p30 as c4, @p31 as c5, @p32 as c6, @p33 as c7, @p34 as c8, @p35 as c9, 
        @p36 as c10, @p37 as c11, @p38 as c12, @p39 as rowguid union all
    select @p40 as c1, @p41 as c2, @p42 as c3, @p43 as c4, @p44 as c5, @p45 as c6, @p46 as c7, @p47 as c8, @p48 as c9, 
        @p49 as c10, @p50 as c11, @p51 as c12, @p52 as rowguid union all
    select @p53 as c1, @p54 as c2, @p55 as c3, @p56 as c4, @p57 as c5, @p58 as c6, @p59 as c7, @p60 as c8, @p61 as c9, 
        @p62 as c10, @p63 as c11, @p64 as c12, @p65 as rowguid union all
    select @p66 as c1, @p67 as c2, @p68 as c3, @p69 as c4, @p70 as c5, @p71 as c6, @p72 as c7, @p73 as c8, @p74 as c9, 
        @p75 as c10, @p76 as c11, @p77 as c12, @p78 as rowguid union all
    select @p79 as c1, @p80 as c2, @p81 as c3, @p82 as c4, @p83 as c5, @p84 as c6, @p85 as c7, @p86 as c8, @p87 as c9, 
        @p88 as c10, @p89 as c11, @p90 as c12, @p91 as rowguid union all
    select @p92 as c1, @p93 as c2, @p94 as c3, @p95 as c4, @p96 as c5, @p97 as c6, @p98 as c7, @p99 as c8, @p100 as c9, 
        @p101 as c10, @p102 as c11, @p103 as c12, @p104 as rowguid union all
    select @p105 as c1, @p106 as c2, @p107 as c3, @p108 as c4, @p109 as c5, @p110 as c6, @p111 as c7, @p112 as c8, @p113 as c9, 
        @p114 as c10, @p115 as c11, @p116 as c12, @p117 as rowguid union all
    select @p118 as c1, @p119 as c2, @p120 as c3, @p121 as c4, @p122 as c5, @p123 as c6, @p124 as c7, @p125 as c8, @p126 as c9, 
        @p127 as c10, @p128 as c11, @p129 as c12, @p130 as rowguid union all
    select @p131 as c1, @p132 as c2, @p133 as c3, @p134 as c4, @p135 as c5, @p136 as c6, @p137 as c7, @p138 as c8, @p139 as c9, 
        @p140 as c10, @p141 as c11, @p142 as c12, @p143 as rowguid union all
    select @p144 as c1, @p145 as c2, @p146 as c3, @p147 as c4, @p148 as c5, @p149 as c6, @p150 as c7, @p151 as c8, @p152 as c9, 
        @p153 as c10, @p154 as c11, @p155 as c12, @p156 as rowguid union all
    select @p157 as c1, @p158 as c2, @p159 as c3, @p160 as c4, @p161 as c5, @p162 as c6, @p163 as c7, @p164 as c8, @p165 as c9, 
        @p166 as c10, @p167 as c11, @p168 as c12, @p169 as rowguid union all
    select @p170 as c1, @p171 as c2, @p172 as c3, @p173 as c4, @p174 as c5, @p175 as c6, @p176 as c7, @p177 as c8, @p178 as c9, 
        @p179 as c10, @p180 as c11, @p181 as c12, @p182 as rowguid union all
    select @p183 as c1, @p184 as c2, @p185 as c3, @p186 as c4, @p187 as c5, @p188 as c6, @p189 as c7, @p190 as c8, @p191 as c9, 
        @p192 as c10, @p193 as c11, @p194 as c12, @p195 as rowguid union all
    select @p196 as c1, @p197 as c2, @p198 as c3, @p199 as c4, @p200 as c5, @p201 as c6, @p202 as c7, @p203 as c8, @p204 as c9, 
        @p205 as c10, @p206 as c11, @p207 as c12, @p208 as rowguid union all
    select @p209 as c1, @p210 as c2, @p211 as c3, @p212 as c4, @p213 as c5, @p214 as c6, @p215 as c7, @p216 as c8, @p217 as c9, 
        @p218 as c10, @p219 as c11, @p220 as c12, @p221 as rowguid union all
    select @p222 as c1, @p223 as c2, @p224 as c3, @p225 as c4, @p226 as c5, @p227 as c6, @p228 as c7, @p229 as c8, @p230 as c9, 
        @p231 as c10, @p232 as c11, @p233 as c12, @p234 as rowguid union all
    select @p235 as c1, @p236 as c2, @p237 as c3, @p238 as c4, @p239 as c5, @p240 as c6, @p241 as c7, @p242 as c8
, @p243 as c9, 
        @p244 as c10, @p245 as c11, @p246 as c12, @p247 as rowguid union all
    select @p248 as c1, @p249 as c2, @p250 as c3, @p251 as c4, @p252 as c5, @p253 as c6, @p254 as c7, @p255 as c8, @p256 as c9, 
        @p257 as c10, @p258 as c11, @p259 as c12, @p260 as rowguid union all
    select @p261 as c1, @p262 as c2, @p263 as c3, @p264 as c4, @p265 as c5, @p266 as c6, @p267 as c7, @p268 as c8, @p269 as c9, 
        @p270 as c10, @p271 as c11, @p272 as c12, @p273 as rowguid union all
    select @p274 as c1, @p275 as c2, @p276 as c3, @p277 as c4, @p278 as c5, @p279 as c6, @p280 as c7, @p281 as c8, @p282 as c9, 
        @p283 as c10, @p284 as c11, @p285 as c12, @p286 as rowguid union all
    select @p287 as c1, @p288 as c2, @p289 as c3, @p290 as c4, @p291 as c5, @p292 as c6, @p293 as c7, @p294 as c8, @p295 as c9, 
        @p296 as c10, @p297 as c11, @p298 as c12, @p299 as rowguid union all
    select @p300 as c1, @p301 as c2, @p302 as c3, @p303 as c4, @p304 as c5, @p305 as c6, @p306 as c7, @p307 as c8, @p308 as c9, 
        @p309 as c10, @p310 as c11, @p311 as c12, @p312 as rowguid union all
    select @p313 as c1, @p314 as c2, @p315 as c3, @p316 as c4, @p317 as c5, @p318 as c6, @p319 as c7, @p320 as c8, @p321 as c9, 
        @p322 as c10, @p323 as c11, @p324 as c12, @p325 as rowguid union all
    select @p326 as c1, @p327 as c2, @p328 as c3, @p329 as c4, @p330 as c5, @p331 as c6, @p332 as c7, @p333 as c8, @p334 as c9, 
        @p335 as c10, @p336 as c11, @p337 as c12, @p338 as rowguid union all
    select @p339 as c1, @p340 as c2, @p341 as c3, @p342 as c4, @p343 as c5, @p344 as c6, @p345 as c7, @p346 as c8, @p347 as c9, 
        @p348 as c10, @p349 as c11, @p350 as c12, @p351 as rowguid union all
    select @p352 as c1, @p353 as c2, @p354 as c3, @p355 as c4, @p356 as c5, @p357 as c6, @p358 as c7, @p359 as c8, @p360 as c9, 
        @p361 as c10, @p362 as c11, @p363 as c12, @p364 as rowguid union all
    select @p365 as c1, @p366 as c2, @p367 as c3, @p368 as c4, @p369 as c5, @p370 as c6, @p371 as c7, @p372 as c8, @p373 as c9, 
        @p374 as c10, @p375 as c11, @p376 as c12, @p377 as rowguid union all
    select @p378 as c1, @p379 as c2, @p380 as c3, @p381 as c4, @p382 as c5, @p383 as c6, @p384 as c7, @p385 as c8, @p386 as c9, 
        @p387 as c10, @p388 as c11, @p389 as c12, @p390 as rowguid union all
    select @p391 as c1, @p392 as c2, @p393 as c3, @p394 as c4, @p395 as c5, @p396 as c6, @p397 as c7, @p398 as c8, @p399 as c9, 
        @p400 as c10, @p401 as c11, @p402 as c12, @p403 as rowguid union all
    select @p404 as c1, @p405 as c2, @p406 as c3, @p407 as c4, @p408 as c5, @p409 as c6, @p410 as c7, @p411 as c8, @p412 as c9, 
        @p413 as c10, @p414 as c11, @p415 as c12, @p416 as rowguid union all
    select @p417 as c1, @p418 as c2, @p419 as c3, @p420 as c4, @p421 as c5, @p422 as c6, @p423 as c7, @p424 as c8, @p425 as c9, 
        @p426 as c10, @p427 as c11, @p428 as c12, @p429 as rowguid union all
    select @p430 as c1, @p431 as c2, @p432 as c3, @p433 as c4, @p434 as c5, @p435 as c6, @p436 as c7, @p437 as c8, @p438 as c9, 
        @p439 as c10, @p440 as c11, @p441 as c12, @p442 as rowguid union all
    select @p443 as c1, @p444 as c2, @p445 as c3, @p446 as c4, @p447 as c5, @p448 as c6, @p449 as c7, @p450 as c8, @p451 as c9, 
        @p452 as c10, @p453 as c11, @p454 as c12, @p455 as rowguid union all
    select @p456 as c1, @p457 as c2, @p458 as c3, @p459 as c4, @p460 as c5, @p461 as c6, @p462 as c7, @p463 as c8, @p464 as c9, 
        @p465 as c10, @p466 as c11, @p467 as c12, @p468 as rowguid union all
    select @p469 as c1, @p470 as c2, @p471 as c3, @p472 as c4, @p473 as c5, @p474 as c6, @p475 as c7, @p476 as c8, @p477 as c9
, 
        @p478 as c10, @p479 as c11, @p480 as c12, @p481 as rowguid union all
    select @p482 as c1, @p483 as c2, @p484 as c3, @p485 as c4, @p486 as c5, @p487 as c6, @p488 as c7, @p489 as c8, @p490 as c9, 
        @p491 as c10, @p492 as c11, @p493 as c12, @p494 as rowguid union all
    select @p495 as c1, @p496 as c2, @p497 as c3, @p498 as c4, @p499 as c5, @p500 as c6, @p501 as c7, @p502 as c8, @p503 as c9, 
        @p504 as c10, @p505 as c11, @p506 as c12, @p507 as rowguid union all
    select @p508 as c1, @p509 as c2, @p510 as c3, @p511 as c4, @p512 as c5, @p513 as c6, @p514 as c7, @p515 as c8, @p516 as c9, 
        @p517 as c10, @p518 as c11, @p519 as c12, @p520 as rowguid union all
    select @p521 as c1, @p522 as c2, @p523 as c3, @p524 as c4, @p525 as c5, @p526 as c6, @p527 as c7, @p528 as c8, @p529 as c9, 
        @p530 as c10, @p531 as c11, @p532 as c12, @p533 as rowguid union all
    select @p534 as c1, @p535 as c2, @p536 as c3, @p537 as c4, @p538 as c5, @p539 as c6, @p540 as c7, @p541 as c8, @p542 as c9, 
        @p543 as c10, @p544 as c11, @p545 as c12, @p546 as rowguid union all
    select @p547 as c1, @p548 as c2, @p549 as c3, @p550 as c4, @p551 as c5, @p552 as c6, @p553 as c7, @p554 as c8, @p555 as c9, 
        @p556 as c10, @p557 as c11, @p558 as c12, @p559 as rowguid union all
    select @p560 as c1, @p561 as c2, @p562 as c3, @p563 as c4, @p564 as c5, @p565 as c6, @p566 as c7, @p567 as c8, @p568 as c9, 
        @p569 as c10, @p570 as c11, @p571 as c12, @p572 as rowguid union all
    select @p573 as c1, @p574 as c2, @p575 as c3, @p576 as c4, @p577 as c5, @p578 as c6, @p579 as c7, @p580 as c8, @p581 as c9, 
        @p582 as c10, @p583 as c11, @p584 as c12, @p585 as rowguid union all
    select @p586 as c1, @p587 as c2, @p588 as c3, @p589 as c4, @p590 as c5, @p591 as c6, @p592 as c7, @p593 as c8, @p594 as c9, 
        @p595 as c10, @p596 as c11, @p597 as c12, @p598 as rowguid union all
    select @p599 as c1, @p600 as c2, @p601 as c3, @p602 as c4, @p603 as c5, @p604 as c6, @p605 as c7, @p606 as c8, @p607 as c9, 
        @p608 as c10, @p609 as c11, @p610 as c12, @p611 as rowguid union all
    select @p612 as c1, @p613 as c2, @p614 as c3, @p615 as c4, @p616 as c5, @p617 as c6, @p618 as c7, @p619 as c8, @p620 as c9, 
        @p621 as c10, @p622 as c11, @p623 as c12, @p624 as rowguid union all
    select @p625 as c1, @p626 as c2, @p627 as c3, @p628 as c4, @p629 as c5, @p630 as c6, @p631 as c7, @p632 as c8, @p633 as c9, 
        @p634 as c10, @p635 as c11, @p636 as c12, @p637 as rowguid union all
    select @p638 as c1, @p639 as c2, @p640 as c3, @p641 as c4, @p642 as c5, @p643 as c6, @p644 as c7, @p645 as c8, @p646 as c9, 
        @p647 as c10, @p648 as c11, @p649 as c12, @p650 as rowguid union all
    select @p651 as c1, @p652 as c2, @p653 as c3, @p654 as c4, @p655 as c5, @p656 as c6, @p657 as c7, @p658 as c8, @p659 as c9, 
        @p660 as c10, @p661 as c11, @p662 as c12, @p663 as rowguid union all
    select @p664 as c1, @p665 as c2, @p666 as c3, @p667 as c4, @p668 as c5, @p669 as c6, @p670 as c7, @p671 as c8, @p672 as c9, 
        @p673 as c10, @p674 as c11, @p675 as c12, @p676 as rowguid union all
    select @p677 as c1, @p678 as c2, @p679 as c3, @p680 as c4, @p681 as c5, @p682 as c6, @p683 as c7, @p684 as c8, @p685 as c9, 
        @p686 as c10, @p687 as c11, @p688 as c12, @p689 as rowguid union all
    select @p690 as c1, @p691 as c2, @p692 as c3, @p693 as c4, @p694 as c5, @p695 as c6, @p696 as c7, @p697 as c8, @p698 as c9, 
        @p699 as c10, @p700 as c11, @p701 as c12, @p702 as rowguid union all
    select @p703 as c1, @p704 as c2, @p705 as c3, @p706 as c4, @p707 as c5, @p708 as c6, @p709 as c7, @p710 as c8, @p711 as c9, 
        @p712 as c10
, @p713 as c11, @p714 as c12, @p715 as rowguid union all
    select @p716 as c1, @p717 as c2, @p718 as c3, @p719 as c4, @p720 as c5, @p721 as c6, @p722 as c7, @p723 as c8, @p724 as c9, 
        @p725 as c10, @p726 as c11, @p727 as c12, @p728 as rowguid union all
    select @p729 as c1, @p730 as c2, @p731 as c3, @p732 as c4, @p733 as c5, @p734 as c6, @p735 as c7, @p736 as c8, @p737 as c9, 
        @p738 as c10, @p739 as c11, @p740 as c12, @p741 as rowguid union all
    select @p742 as c1, @p743 as c2, @p744 as c3, @p745 as c4, @p746 as c5, @p747 as c6, @p748 as c7, @p749 as c8, @p750 as c9, 
        @p751 as c10, @p752 as c11, @p753 as c12, @p754 as rowguid union all
    select @p755 as c1, @p756 as c2, @p757 as c3, @p758 as c4, @p759 as c5, @p760 as c6, @p761 as c7, @p762 as c8, @p763 as c9, 
        @p764 as c10, @p765 as c11, @p766 as c12, @p767 as rowguid union all
    select @p768 as c1
, @p769 as c2
, @p770 as c3
, @p771 as c4
, @p772 as c5
, @p773 as c6
, @p774 as c7
, @p775 as c8
, @p776 as c9
, 
        @p777 as c10
, @p778 as c11
, @p779 as c12
, @p780 as rowguid

    ) as rows
    where rows.rowguid is not NULL
    select @rowcount = @@rowcount, @error = @@error

    if (@rowcount <> @rows_tobe_inserted) or (@error <> 0)
    begin
        set @errcode= 3
        goto Failure
    end


    exec @retcode = sys.sp_MSdeletemetadataactionrequest '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800', 49871000, 
        @rowguid1, 
        @rowguid2, 
        @rowguid3, 
        @rowguid4, 
        @rowguid5, 
        @rowguid6, 
        @rowguid7, 
        @rowguid8, 
        @rowguid9, 
        @rowguid10, 
        @rowguid11, 
        @rowguid12, 
        @rowguid13, 
        @rowguid14, 
        @rowguid15, 
        @rowguid16, 
        @rowguid17, 
        @rowguid18, 
        @rowguid19, 
        @rowguid20, 
        @rowguid21, 
        @rowguid22, 
        @rowguid23, 
        @rowguid24, 
        @rowguid25, 
        @rowguid26, 
        @rowguid27, 
        @rowguid28, 
        @rowguid29, 
        @rowguid30, 
        @rowguid31, 
        @rowguid32, 
        @rowguid33, 
        @rowguid34, 
        @rowguid35, 
        @rowguid36, 
        @rowguid37, 
        @rowguid38, 
        @rowguid39, 
        @rowguid40, 
        @rowguid41, 
        @rowguid42, 
        @rowguid43, 
        @rowguid44, 
        @rowguid45, 
        @rowguid46, 
        @rowguid47, 
        @rowguid48, 
        @rowguid49, 
        @rowguid50, 
        @rowguid51, 
        @rowguid52, 
        @rowguid53, 
        @rowguid54, 
        @rowguid55, 
        @rowguid56, 
        @rowguid57, 
        @rowguid58, 
        @rowguid59, 
        @rowguid60
    if @retcode<>0 or @@error<>0
        goto Failure
    

    commit tran
    return 1

Failure:
    rollback tran batchinsertproc
    commit tran
    return 0
end


go
create procedure dbo.[MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B_batch] (
        @rows_tobe_updated int,
        @partition_id int = null 
,
    @rowguid1 uniqueidentifier = NULL,
    @setbm1 varbinary(125) = NULL,
    @metadata_type1 tinyint = NULL,
    @lineage_old1 varbinary(311) = NULL,
    @generation1 bigint = NULL,
    @lineage_new1 varbinary(311) = NULL,
    @colv1 varbinary(1) = NULL,
    @p1 varchar(10) = NULL,
    @p2 varchar(10) = NULL,
    @p3 varchar(10) = NULL,
    @p4 nvarchar(50) = NULL,
    @p5 int = NULL,
    @p6 nvarchar(50) = NULL,
    @p7 int = NULL,
    @p8 varchar(50) = NULL,
    @p9 nvarchar(max) = NULL,
    @p10 nvarchar(50) = NULL,
    @p11 nvarchar(50) = NULL,
    @p12 nvarchar(50) = NULL,
    @p13 uniqueidentifier = NULL,
    @rowguid2 uniqueidentifier = NULL,
    @setbm2 varbinary(125) = NULL,
    @metadata_type2 tinyint = NULL,
    @lineage_old2 varbinary(311) = NULL,
    @generation2 bigint = NULL,
    @lineage_new2 varbinary(311) = NULL,
    @colv2 varbinary(1) = NULL,
    @p14 varchar(10) = NULL,
    @p15 varchar(10) = NULL,
    @p16 varchar(10) = NULL,
    @p17 nvarchar(50) = NULL,
    @p18 int = NULL,
    @p19 nvarchar(50) = NULL,
    @p20 int = NULL,
    @p21 varchar(50) = NULL,
    @p22 nvarchar(max) = NULL,
    @p23 nvarchar(50) = NULL,
    @p24 nvarchar(50) = NULL,
    @p25 nvarchar(50) = NULL,
    @p26 uniqueidentifier = NULL,
    @rowguid3 uniqueidentifier = NULL,
    @setbm3 varbinary(125) = NULL,
    @metadata_type3 tinyint = NULL,
    @lineage_old3 varbinary(311) = NULL,
    @generation3 bigint = NULL,
    @lineage_new3 varbinary(311) = NULL,
    @colv3 varbinary(1) = NULL,
    @p27 varchar(10) = NULL,
    @p28 varchar(10) = NULL,
    @p29 varchar(10) = NULL,
    @p30 nvarchar(50) = NULL,
    @p31 int = NULL,
    @p32 nvarchar(50) = NULL,
    @p33 int = NULL,
    @p34 varchar(50) = NULL,
    @p35 nvarchar(max) = NULL,
    @p36 nvarchar(50) = NULL,
    @p37 nvarchar(50) = NULL,
    @p38 nvarchar(50) = NULL,
    @p39 uniqueidentifier = NULL,
    @rowguid4 uniqueidentifier = NULL,
    @setbm4 varbinary(125) = NULL,
    @metadata_type4 tinyint = NULL,
    @lineage_old4 varbinary(311) = NULL,
    @generation4 bigint = NULL,
    @lineage_new4 varbinary(311) = NULL,
    @colv4 varbinary(1) = NULL,
    @p40 varchar(10) = NULL,
    @p41 varchar(10) = NULL,
    @p42 varchar(10) = NULL,
    @p43 nvarchar(50) = NULL,
    @p44 int = NULL,
    @p45 nvarchar(50) = NULL,
    @p46 int = NULL,
    @p47 varchar(50) = NULL,
    @p48 nvarchar(max) = NULL,
    @p49 nvarchar(50) = NULL,
    @p50 nvarchar(50) = NULL,
    @p51 nvarchar(50) = NULL,
    @p52 uniqueidentifier = NULL,
    @rowguid5 uniqueidentifier = NULL,
    @setbm5 varbinary(125) = NULL,
    @metadata_type5 tinyint = NULL,
    @lineage_old5 varbinary(311) = NULL,
    @generation5 bigint = NULL,
    @lineage_new5 varbinary(311) = NULL,
    @colv5 varbinary(1) = NULL,
    @p53 varchar(10) = NULL,
    @p54 varchar(10) = NULL,
    @p55 varchar(10) = NULL,
    @p56 nvarchar(50) = NULL,
    @p57 int = NULL,
    @p58 nvarchar(50) = NULL,
    @p59 int = NULL,
    @p60 varchar(50) = NULL,
    @p61 nvarchar(max) = NULL,
    @p62 nvarchar(50) = NULL,
    @p63 nvarchar(50) = NULL,
    @p64 nvarchar(50) = NULL,
    @p65 uniqueidentifier = NULL,
    @rowguid6 uniqueidentifier = NULL,
    @setbm6 varbinary(125) = NULL,
    @metadata_type6 tinyint = NULL,
    @lineage_old6 varbinary(311) = NULL,
    @generation6 bigint = NULL,
    @lineage_new6 varbinary(311) = NULL,
    @colv6 varbinary(1) = NULL,
    @p66 varchar(10) = NULL
,
    @p67 varchar(10) = NULL,
    @p68 varchar(10) = NULL,
    @p69 nvarchar(50) = NULL,
    @p70 int = NULL,
    @p71 nvarchar(50) = NULL,
    @p72 int = NULL,
    @p73 varchar(50) = NULL,
    @p74 nvarchar(max) = NULL,
    @p75 nvarchar(50) = NULL,
    @p76 nvarchar(50) = NULL,
    @p77 nvarchar(50) = NULL,
    @p78 uniqueidentifier = NULL,
    @rowguid7 uniqueidentifier = NULL,
    @setbm7 varbinary(125) = NULL,
    @metadata_type7 tinyint = NULL,
    @lineage_old7 varbinary(311) = NULL,
    @generation7 bigint = NULL,
    @lineage_new7 varbinary(311) = NULL,
    @colv7 varbinary(1) = NULL,
    @p79 varchar(10) = NULL,
    @p80 varchar(10) = NULL,
    @p81 varchar(10) = NULL,
    @p82 nvarchar(50) = NULL,
    @p83 int = NULL,
    @p84 nvarchar(50) = NULL,
    @p85 int = NULL,
    @p86 varchar(50) = NULL,
    @p87 nvarchar(max) = NULL,
    @p88 nvarchar(50) = NULL,
    @p89 nvarchar(50) = NULL,
    @p90 nvarchar(50) = NULL,
    @p91 uniqueidentifier = NULL,
    @rowguid8 uniqueidentifier = NULL,
    @setbm8 varbinary(125) = NULL,
    @metadata_type8 tinyint = NULL,
    @lineage_old8 varbinary(311) = NULL,
    @generation8 bigint = NULL,
    @lineage_new8 varbinary(311) = NULL,
    @colv8 varbinary(1) = NULL,
    @p92 varchar(10) = NULL,
    @p93 varchar(10) = NULL,
    @p94 varchar(10) = NULL,
    @p95 nvarchar(50) = NULL,
    @p96 int = NULL,
    @p97 nvarchar(50) = NULL,
    @p98 int = NULL,
    @p99 varchar(50) = NULL,
    @p100 nvarchar(max) = NULL,
    @p101 nvarchar(50) = NULL,
    @p102 nvarchar(50) = NULL,
    @p103 nvarchar(50) = NULL,
    @p104 uniqueidentifier = NULL,
    @rowguid9 uniqueidentifier = NULL,
    @setbm9 varbinary(125) = NULL,
    @metadata_type9 tinyint = NULL,
    @lineage_old9 varbinary(311) = NULL,
    @generation9 bigint = NULL,
    @lineage_new9 varbinary(311) = NULL,
    @colv9 varbinary(1) = NULL,
    @p105 varchar(10) = NULL,
    @p106 varchar(10) = NULL,
    @p107 varchar(10) = NULL,
    @p108 nvarchar(50) = NULL,
    @p109 int = NULL,
    @p110 nvarchar(50) = NULL,
    @p111 int = NULL,
    @p112 varchar(50) = NULL,
    @p113 nvarchar(max) = NULL,
    @p114 nvarchar(50) = NULL,
    @p115 nvarchar(50) = NULL,
    @p116 nvarchar(50) = NULL,
    @p117 uniqueidentifier = NULL,
    @rowguid10 uniqueidentifier = NULL,
    @setbm10 varbinary(125) = NULL,
    @metadata_type10 tinyint = NULL,
    @lineage_old10 varbinary(311) = NULL,
    @generation10 bigint = NULL,
    @lineage_new10 varbinary(311) = NULL,
    @colv10 varbinary(1) = NULL,
    @p118 varchar(10) = NULL,
    @p119 varchar(10) = NULL,
    @p120 varchar(10) = NULL,
    @p121 nvarchar(50) = NULL,
    @p122 int = NULL,
    @p123 nvarchar(50) = NULL,
    @p124 int = NULL,
    @p125 varchar(50) = NULL,
    @p126 nvarchar(max) = NULL,
    @p127 nvarchar(50) = NULL,
    @p128 nvarchar(50) = NULL,
    @p129 nvarchar(50) = NULL,
    @p130 uniqueidentifier = NULL,
    @rowguid11 uniqueidentifier = NULL,
    @setbm11 varbinary(125) = NULL,
    @metadata_type11 tinyint = NULL,
    @lineage_old11 varbinary(311) = NULL,
    @generation11 bigint = NULL,
    @lineage_new11 varbinary(311) = NULL,
    @colv11 varbinary(1) = NULL,
    @p131 varchar(10) = NULL,
    @p132 varchar(10) = NULL,
    @p133 varchar(10) = NULL,
    @p134 nvarchar(50) = NULL,
    @p135 int = NULL,
    @p136 nvarchar(50) = NULL,
    @p137 int = NULL,
    @p138 varchar(50) = NULL,
    @p139 nvarchar(max) = NULL
,
    @p140 nvarchar(50) = NULL,
    @p141 nvarchar(50) = NULL,
    @p142 nvarchar(50) = NULL,
    @p143 uniqueidentifier = NULL,
    @rowguid12 uniqueidentifier = NULL,
    @setbm12 varbinary(125) = NULL,
    @metadata_type12 tinyint = NULL,
    @lineage_old12 varbinary(311) = NULL,
    @generation12 bigint = NULL,
    @lineage_new12 varbinary(311) = NULL,
    @colv12 varbinary(1) = NULL,
    @p144 varchar(10) = NULL,
    @p145 varchar(10) = NULL,
    @p146 varchar(10) = NULL,
    @p147 nvarchar(50) = NULL,
    @p148 int = NULL,
    @p149 nvarchar(50) = NULL,
    @p150 int = NULL,
    @p151 varchar(50) = NULL,
    @p152 nvarchar(max) = NULL,
    @p153 nvarchar(50) = NULL,
    @p154 nvarchar(50) = NULL,
    @p155 nvarchar(50) = NULL,
    @p156 uniqueidentifier = NULL,
    @rowguid13 uniqueidentifier = NULL,
    @setbm13 varbinary(125) = NULL,
    @metadata_type13 tinyint = NULL,
    @lineage_old13 varbinary(311) = NULL,
    @generation13 bigint = NULL,
    @lineage_new13 varbinary(311) = NULL,
    @colv13 varbinary(1) = NULL,
    @p157 varchar(10) = NULL,
    @p158 varchar(10) = NULL,
    @p159 varchar(10) = NULL,
    @p160 nvarchar(50) = NULL,
    @p161 int = NULL,
    @p162 nvarchar(50) = NULL,
    @p163 int = NULL,
    @p164 varchar(50) = NULL,
    @p165 nvarchar(max) = NULL,
    @p166 nvarchar(50) = NULL,
    @p167 nvarchar(50) = NULL,
    @p168 nvarchar(50) = NULL,
    @p169 uniqueidentifier = NULL,
    @rowguid14 uniqueidentifier = NULL,
    @setbm14 varbinary(125) = NULL,
    @metadata_type14 tinyint = NULL,
    @lineage_old14 varbinary(311) = NULL,
    @generation14 bigint = NULL,
    @lineage_new14 varbinary(311) = NULL,
    @colv14 varbinary(1) = NULL,
    @p170 varchar(10) = NULL,
    @p171 varchar(10) = NULL,
    @p172 varchar(10) = NULL,
    @p173 nvarchar(50) = NULL,
    @p174 int = NULL,
    @p175 nvarchar(50) = NULL,
    @p176 int = NULL,
    @p177 varchar(50) = NULL,
    @p178 nvarchar(max) = NULL,
    @p179 nvarchar(50) = NULL,
    @p180 nvarchar(50) = NULL,
    @p181 nvarchar(50) = NULL,
    @p182 uniqueidentifier = NULL,
    @rowguid15 uniqueidentifier = NULL,
    @setbm15 varbinary(125) = NULL,
    @metadata_type15 tinyint = NULL,
    @lineage_old15 varbinary(311) = NULL,
    @generation15 bigint = NULL,
    @lineage_new15 varbinary(311) = NULL,
    @colv15 varbinary(1) = NULL,
    @p183 varchar(10) = NULL,
    @p184 varchar(10) = NULL,
    @p185 varchar(10) = NULL,
    @p186 nvarchar(50) = NULL,
    @p187 int = NULL,
    @p188 nvarchar(50) = NULL,
    @p189 int = NULL,
    @p190 varchar(50) = NULL,
    @p191 nvarchar(max) = NULL,
    @p192 nvarchar(50) = NULL,
    @p193 nvarchar(50) = NULL,
    @p194 nvarchar(50) = NULL,
    @p195 uniqueidentifier = NULL,
    @rowguid16 uniqueidentifier = NULL,
    @setbm16 varbinary(125) = NULL,
    @metadata_type16 tinyint = NULL,
    @lineage_old16 varbinary(311) = NULL,
    @generation16 bigint = NULL,
    @lineage_new16 varbinary(311) = NULL,
    @colv16 varbinary(1) = NULL,
    @p196 varchar(10) = NULL,
    @p197 varchar(10) = NULL,
    @p198 varchar(10) = NULL,
    @p199 nvarchar(50) = NULL,
    @p200 int = NULL,
    @p201 nvarchar(50) = NULL,
    @p202 int = NULL,
    @p203 varchar(50) = NULL,
    @p204 nvarchar(max) = NULL,
    @p205 nvarchar(50) = NULL,
    @p206 nvarchar(50) = NULL,
    @p207 nvarchar(50) = NULL,
    @p208 uniqueidentifier = NULL,
    @rowguid17 uniqueidentifier = NULL,
    @setbm17 varbinary(125) = NULL,
    @metadata_type17 tinyint = NULL,
    @lineage_old17 varbinary(311) = NULL,
    @generation17 bigint = NULL,
    @lineage_new17 varbinary(311) = NULL,
    @colv17 varbinary(1) = NULL,
    @p209 varchar(10) = NULL
,
    @p210 varchar(10) = NULL,
    @p211 varchar(10) = NULL,
    @p212 nvarchar(50) = NULL,
    @p213 int = NULL,
    @p214 nvarchar(50) = NULL,
    @p215 int = NULL,
    @p216 varchar(50) = NULL,
    @p217 nvarchar(max) = NULL,
    @p218 nvarchar(50) = NULL,
    @p219 nvarchar(50) = NULL,
    @p220 nvarchar(50) = NULL,
    @p221 uniqueidentifier = NULL,
    @rowguid18 uniqueidentifier = NULL,
    @setbm18 varbinary(125) = NULL,
    @metadata_type18 tinyint = NULL,
    @lineage_old18 varbinary(311) = NULL,
    @generation18 bigint = NULL,
    @lineage_new18 varbinary(311) = NULL,
    @colv18 varbinary(1) = NULL,
    @p222 varchar(10) = NULL,
    @p223 varchar(10) = NULL,
    @p224 varchar(10) = NULL,
    @p225 nvarchar(50) = NULL,
    @p226 int = NULL,
    @p227 nvarchar(50) = NULL,
    @p228 int = NULL,
    @p229 varchar(50) = NULL,
    @p230 nvarchar(max) = NULL,
    @p231 nvarchar(50) = NULL,
    @p232 nvarchar(50) = NULL,
    @p233 nvarchar(50) = NULL,
    @p234 uniqueidentifier = NULL,
    @rowguid19 uniqueidentifier = NULL,
    @setbm19 varbinary(125) = NULL,
    @metadata_type19 tinyint = NULL,
    @lineage_old19 varbinary(311) = NULL,
    @generation19 bigint = NULL,
    @lineage_new19 varbinary(311) = NULL,
    @colv19 varbinary(1) = NULL,
    @p235 varchar(10) = NULL,
    @p236 varchar(10) = NULL,
    @p237 varchar(10) = NULL,
    @p238 nvarchar(50) = NULL,
    @p239 int = NULL,
    @p240 nvarchar(50) = NULL,
    @p241 int = NULL,
    @p242 varchar(50) = NULL,
    @p243 nvarchar(max) = NULL,
    @p244 nvarchar(50) = NULL,
    @p245 nvarchar(50) = NULL,
    @p246 nvarchar(50) = NULL,
    @p247 uniqueidentifier = NULL,
    @rowguid20 uniqueidentifier = NULL,
    @setbm20 varbinary(125) = NULL,
    @metadata_type20 tinyint = NULL,
    @lineage_old20 varbinary(311) = NULL,
    @generation20 bigint = NULL,
    @lineage_new20 varbinary(311) = NULL,
    @colv20 varbinary(1) = NULL,
    @p248 varchar(10) = NULL,
    @p249 varchar(10) = NULL,
    @p250 varchar(10) = NULL,
    @p251 nvarchar(50) = NULL,
    @p252 int = NULL,
    @p253 nvarchar(50) = NULL,
    @p254 int = NULL,
    @p255 varchar(50) = NULL,
    @p256 nvarchar(max) = NULL,
    @p257 nvarchar(50) = NULL,
    @p258 nvarchar(50) = NULL,
    @p259 nvarchar(50) = NULL,
    @p260 uniqueidentifier = NULL,
    @rowguid21 uniqueidentifier = NULL,
    @setbm21 varbinary(125) = NULL,
    @metadata_type21 tinyint = NULL,
    @lineage_old21 varbinary(311) = NULL,
    @generation21 bigint = NULL,
    @lineage_new21 varbinary(311) = NULL,
    @colv21 varbinary(1) = NULL,
    @p261 varchar(10) = NULL,
    @p262 varchar(10) = NULL,
    @p263 varchar(10) = NULL,
    @p264 nvarchar(50) = NULL,
    @p265 int = NULL,
    @p266 nvarchar(50) = NULL,
    @p267 int = NULL,
    @p268 varchar(50) = NULL,
    @p269 nvarchar(max) = NULL,
    @p270 nvarchar(50) = NULL,
    @p271 nvarchar(50) = NULL,
    @p272 nvarchar(50) = NULL,
    @p273 uniqueidentifier = NULL,
    @rowguid22 uniqueidentifier = NULL,
    @setbm22 varbinary(125) = NULL,
    @metadata_type22 tinyint = NULL,
    @lineage_old22 varbinary(311) = NULL,
    @generation22 bigint = NULL,
    @lineage_new22 varbinary(311) = NULL,
    @colv22 varbinary(1) = NULL,
    @p274 varchar(10) = NULL,
    @p275 varchar(10) = NULL,
    @p276 varchar(10) = NULL,
    @p277 nvarchar(50) = NULL,
    @p278 int = NULL,
    @p279 nvarchar(50) = NULL,
    @p280 int = NULL
,
    @p281 varchar(50) = NULL,
    @p282 nvarchar(max) = NULL,
    @p283 nvarchar(50) = NULL,
    @p284 nvarchar(50) = NULL,
    @p285 nvarchar(50) = NULL,
    @p286 uniqueidentifier = NULL,
    @rowguid23 uniqueidentifier = NULL,
    @setbm23 varbinary(125) = NULL,
    @metadata_type23 tinyint = NULL,
    @lineage_old23 varbinary(311) = NULL,
    @generation23 bigint = NULL,
    @lineage_new23 varbinary(311) = NULL,
    @colv23 varbinary(1) = NULL,
    @p287 varchar(10) = NULL,
    @p288 varchar(10) = NULL,
    @p289 varchar(10) = NULL,
    @p290 nvarchar(50) = NULL,
    @p291 int = NULL,
    @p292 nvarchar(50) = NULL,
    @p293 int = NULL,
    @p294 varchar(50) = NULL,
    @p295 nvarchar(max) = NULL,
    @p296 nvarchar(50) = NULL,
    @p297 nvarchar(50) = NULL,
    @p298 nvarchar(50) = NULL,
    @p299 uniqueidentifier = NULL,
    @rowguid24 uniqueidentifier = NULL,
    @setbm24 varbinary(125) = NULL,
    @metadata_type24 tinyint = NULL,
    @lineage_old24 varbinary(311) = NULL,
    @generation24 bigint = NULL,
    @lineage_new24 varbinary(311) = NULL,
    @colv24 varbinary(1) = NULL,
    @p300 varchar(10) = NULL,
    @p301 varchar(10) = NULL,
    @p302 varchar(10) = NULL,
    @p303 nvarchar(50) = NULL,
    @p304 int = NULL,
    @p305 nvarchar(50) = NULL,
    @p306 int = NULL,
    @p307 varchar(50) = NULL,
    @p308 nvarchar(max) = NULL,
    @p309 nvarchar(50) = NULL,
    @p310 nvarchar(50) = NULL,
    @p311 nvarchar(50) = NULL,
    @p312 uniqueidentifier = NULL,
    @rowguid25 uniqueidentifier = NULL,
    @setbm25 varbinary(125) = NULL,
    @metadata_type25 tinyint = NULL,
    @lineage_old25 varbinary(311) = NULL,
    @generation25 bigint = NULL,
    @lineage_new25 varbinary(311) = NULL,
    @colv25 varbinary(1) = NULL,
    @p313 varchar(10) = NULL,
    @p314 varchar(10) = NULL,
    @p315 varchar(10) = NULL,
    @p316 nvarchar(50) = NULL,
    @p317 int = NULL,
    @p318 nvarchar(50) = NULL,
    @p319 int = NULL,
    @p320 varchar(50) = NULL,
    @p321 nvarchar(max) = NULL,
    @p322 nvarchar(50) = NULL,
    @p323 nvarchar(50) = NULL,
    @p324 nvarchar(50) = NULL,
    @p325 uniqueidentifier = NULL,
    @rowguid26 uniqueidentifier = NULL,
    @setbm26 varbinary(125) = NULL,
    @metadata_type26 tinyint = NULL,
    @lineage_old26 varbinary(311) = NULL,
    @generation26 bigint = NULL,
    @lineage_new26 varbinary(311) = NULL,
    @colv26 varbinary(1) = NULL,
    @p326 varchar(10) = NULL,
    @p327 varchar(10) = NULL,
    @p328 varchar(10) = NULL,
    @p329 nvarchar(50) = NULL,
    @p330 int = NULL,
    @p331 nvarchar(50) = NULL,
    @p332 int = NULL,
    @p333 varchar(50) = NULL,
    @p334 nvarchar(max) = NULL,
    @p335 nvarchar(50) = NULL,
    @p336 nvarchar(50) = NULL,
    @p337 nvarchar(50) = NULL,
    @p338 uniqueidentifier = NULL,
    @rowguid27 uniqueidentifier = NULL,
    @setbm27 varbinary(125) = NULL,
    @metadata_type27 tinyint = NULL,
    @lineage_old27 varbinary(311) = NULL,
    @generation27 bigint = NULL,
    @lineage_new27 varbinary(311) = NULL,
    @colv27 varbinary(1) = NULL,
    @p339 varchar(10) = NULL,
    @p340 varchar(10) = NULL,
    @p341 varchar(10) = NULL,
    @p342 nvarchar(50) = NULL,
    @p343 int = NULL,
    @p344 nvarchar(50) = NULL,
    @p345 int = NULL,
    @p346 varchar(50) = NULL,
    @p347 nvarchar(max) = NULL,
    @p348 nvarchar(50) = NULL,
    @p349 nvarchar(50) = NULL,
    @p350 nvarchar(50) = NULL
,
    @p351 uniqueidentifier = NULL,
    @rowguid28 uniqueidentifier = NULL,
    @setbm28 varbinary(125) = NULL,
    @metadata_type28 tinyint = NULL,
    @lineage_old28 varbinary(311) = NULL,
    @generation28 bigint = NULL,
    @lineage_new28 varbinary(311) = NULL,
    @colv28 varbinary(1) = NULL,
    @p352 varchar(10) = NULL,
    @p353 varchar(10) = NULL,
    @p354 varchar(10) = NULL,
    @p355 nvarchar(50) = NULL,
    @p356 int = NULL,
    @p357 nvarchar(50) = NULL,
    @p358 int = NULL,
    @p359 varchar(50) = NULL,
    @p360 nvarchar(max) = NULL,
    @p361 nvarchar(50) = NULL,
    @p362 nvarchar(50) = NULL,
    @p363 nvarchar(50) = NULL,
    @p364 uniqueidentifier = NULL,
    @rowguid29 uniqueidentifier = NULL,
    @setbm29 varbinary(125) = NULL,
    @metadata_type29 tinyint = NULL,
    @lineage_old29 varbinary(311) = NULL,
    @generation29 bigint = NULL,
    @lineage_new29 varbinary(311) = NULL,
    @colv29 varbinary(1) = NULL,
    @p365 varchar(10) = NULL,
    @p366 varchar(10) = NULL,
    @p367 varchar(10) = NULL,
    @p368 nvarchar(50) = NULL,
    @p369 int = NULL,
    @p370 nvarchar(50) = NULL,
    @p371 int = NULL,
    @p372 varchar(50) = NULL,
    @p373 nvarchar(max) = NULL,
    @p374 nvarchar(50) = NULL,
    @p375 nvarchar(50) = NULL,
    @p376 nvarchar(50) = NULL,
    @p377 uniqueidentifier = NULL,
    @rowguid30 uniqueidentifier = NULL,
    @setbm30 varbinary(125) = NULL,
    @metadata_type30 tinyint = NULL,
    @lineage_old30 varbinary(311) = NULL,
    @generation30 bigint = NULL,
    @lineage_new30 varbinary(311) = NULL,
    @colv30 varbinary(1) = NULL,
    @p378 varchar(10) = NULL,
    @p379 varchar(10) = NULL,
    @p380 varchar(10) = NULL,
    @p381 nvarchar(50) = NULL,
    @p382 int = NULL,
    @p383 nvarchar(50) = NULL,
    @p384 int = NULL,
    @p385 varchar(50) = NULL,
    @p386 nvarchar(max) = NULL,
    @p387 nvarchar(50) = NULL,
    @p388 nvarchar(50) = NULL,
    @p389 nvarchar(50) = NULL,
    @p390 uniqueidentifier = NULL,
    @rowguid31 uniqueidentifier = NULL,
    @setbm31 varbinary(125) = NULL,
    @metadata_type31 tinyint = NULL,
    @lineage_old31 varbinary(311) = NULL,
    @generation31 bigint = NULL,
    @lineage_new31 varbinary(311) = NULL,
    @colv31 varbinary(1) = NULL,
    @p391 varchar(10) = NULL,
    @p392 varchar(10) = NULL,
    @p393 varchar(10) = NULL,
    @p394 nvarchar(50) = NULL,
    @p395 int = NULL,
    @p396 nvarchar(50) = NULL,
    @p397 int = NULL,
    @p398 varchar(50) = NULL,
    @p399 nvarchar(max) = NULL,
    @p400 nvarchar(50) = NULL,
    @p401 nvarchar(50) = NULL,
    @p402 nvarchar(50) = NULL,
    @p403 uniqueidentifier = NULL,
    @rowguid32 uniqueidentifier = NULL,
    @setbm32 varbinary(125) = NULL,
    @metadata_type32 tinyint = NULL,
    @lineage_old32 varbinary(311) = NULL,
    @generation32 bigint = NULL,
    @lineage_new32 varbinary(311) = NULL,
    @colv32 varbinary(1) = NULL,
    @p404 varchar(10) = NULL,
    @p405 varchar(10) = NULL,
    @p406 varchar(10) = NULL,
    @p407 nvarchar(50) = NULL,
    @p408 int = NULL,
    @p409 nvarchar(50) = NULL,
    @p410 int = NULL,
    @p411 varchar(50) = NULL,
    @p412 nvarchar(max) = NULL,
    @p413 nvarchar(50) = NULL,
    @p414 nvarchar(50) = NULL,
    @p415 nvarchar(50) = NULL,
    @p416 uniqueidentifier = NULL,
    @rowguid33 uniqueidentifier = NULL,
    @setbm33 varbinary(125) = NULL,
    @metadata_type33 tinyint = NULL,
    @lineage_old33 varbinary(311) = NULL,
    @generation33 bigint = NULL,
    @lineage_new33 varbinary(311) = NULL,
    @colv33 varbinary(1) = NULL,
    @p417 varchar(10) = NULL
,
    @p418 varchar(10) = NULL,
    @p419 varchar(10) = NULL,
    @p420 nvarchar(50) = NULL,
    @p421 int = NULL,
    @p422 nvarchar(50) = NULL,
    @p423 int = NULL,
    @p424 varchar(50) = NULL,
    @p425 nvarchar(max) = NULL,
    @p426 nvarchar(50) = NULL,
    @p427 nvarchar(50) = NULL,
    @p428 nvarchar(50) = NULL,
    @p429 uniqueidentifier = NULL,
    @rowguid34 uniqueidentifier = NULL,
    @setbm34 varbinary(125) = NULL,
    @metadata_type34 tinyint = NULL,
    @lineage_old34 varbinary(311) = NULL,
    @generation34 bigint = NULL,
    @lineage_new34 varbinary(311) = NULL,
    @colv34 varbinary(1) = NULL,
    @p430 varchar(10) = NULL,
    @p431 varchar(10) = NULL,
    @p432 varchar(10) = NULL,
    @p433 nvarchar(50) = NULL,
    @p434 int = NULL,
    @p435 nvarchar(50) = NULL,
    @p436 int = NULL,
    @p437 varchar(50) = NULL,
    @p438 nvarchar(max) = NULL,
    @p439 nvarchar(50) = NULL,
    @p440 nvarchar(50) = NULL,
    @p441 nvarchar(50) = NULL,
    @p442 uniqueidentifier = NULL,
    @rowguid35 uniqueidentifier = NULL,
    @setbm35 varbinary(125) = NULL,
    @metadata_type35 tinyint = NULL,
    @lineage_old35 varbinary(311) = NULL,
    @generation35 bigint = NULL,
    @lineage_new35 varbinary(311) = NULL,
    @colv35 varbinary(1) = NULL,
    @p443 varchar(10) = NULL,
    @p444 varchar(10) = NULL,
    @p445 varchar(10) = NULL,
    @p446 nvarchar(50) = NULL,
    @p447 int = NULL,
    @p448 nvarchar(50) = NULL,
    @p449 int = NULL,
    @p450 varchar(50) = NULL,
    @p451 nvarchar(max) = NULL,
    @p452 nvarchar(50) = NULL,
    @p453 nvarchar(50) = NULL,
    @p454 nvarchar(50) = NULL,
    @p455 uniqueidentifier = NULL,
    @rowguid36 uniqueidentifier = NULL,
    @setbm36 varbinary(125) = NULL,
    @metadata_type36 tinyint = NULL,
    @lineage_old36 varbinary(311) = NULL,
    @generation36 bigint = NULL,
    @lineage_new36 varbinary(311) = NULL,
    @colv36 varbinary(1) = NULL,
    @p456 varchar(10) = NULL,
    @p457 varchar(10) = NULL,
    @p458 varchar(10) = NULL,
    @p459 nvarchar(50) = NULL,
    @p460 int = NULL,
    @p461 nvarchar(50) = NULL,
    @p462 int = NULL,
    @p463 varchar(50) = NULL,
    @p464 nvarchar(max) = NULL,
    @p465 nvarchar(50) = NULL,
    @p466 nvarchar(50) = NULL,
    @p467 nvarchar(50) = NULL,
    @p468 uniqueidentifier = NULL,
    @rowguid37 uniqueidentifier = NULL,
    @setbm37 varbinary(125) = NULL,
    @metadata_type37 tinyint = NULL,
    @lineage_old37 varbinary(311) = NULL,
    @generation37 bigint = NULL,
    @lineage_new37 varbinary(311) = NULL,
    @colv37 varbinary(1) = NULL,
    @p469 varchar(10) = NULL,
    @p470 varchar(10) = NULL,
    @p471 varchar(10) = NULL,
    @p472 nvarchar(50) = NULL,
    @p473 int = NULL,
    @p474 nvarchar(50) = NULL,
    @p475 int = NULL,
    @p476 varchar(50) = NULL,
    @p477 nvarchar(max) = NULL,
    @p478 nvarchar(50) = NULL,
    @p479 nvarchar(50) = NULL,
    @p480 nvarchar(50) = NULL,
    @p481 uniqueidentifier = NULL,
    @rowguid38 uniqueidentifier = NULL,
    @setbm38 varbinary(125) = NULL,
    @metadata_type38 tinyint = NULL,
    @lineage_old38 varbinary(311) = NULL,
    @generation38 bigint = NULL,
    @lineage_new38 varbinary(311) = NULL,
    @colv38 varbinary(1) = NULL,
    @p482 varchar(10) = NULL,
    @p483 varchar(10) = NULL,
    @p484 varchar(10) = NULL,
    @p485 nvarchar(50) = NULL,
    @p486 int = NULL,
    @p487 nvarchar(50) = NULL,
    @p488 int = NULL
,
    @p489 varchar(50) = NULL,
    @p490 nvarchar(max) = NULL,
    @p491 nvarchar(50) = NULL,
    @p492 nvarchar(50) = NULL,
    @p493 nvarchar(50) = NULL,
    @p494 uniqueidentifier = NULL,
    @rowguid39 uniqueidentifier = NULL,
    @setbm39 varbinary(125) = NULL,
    @metadata_type39 tinyint = NULL,
    @lineage_old39 varbinary(311) = NULL,
    @generation39 bigint = NULL,
    @lineage_new39 varbinary(311) = NULL,
    @colv39 varbinary(1) = NULL,
    @p495 varchar(10) = NULL,
    @p496 varchar(10) = NULL,
    @p497 varchar(10) = NULL,
    @p498 nvarchar(50) = NULL,
    @p499 int = NULL,
    @p500 nvarchar(50) = NULL,
    @p501 int = NULL,
    @p502 varchar(50) = NULL,
    @p503 nvarchar(max) = NULL,
    @p504 nvarchar(50) = NULL,
    @p505 nvarchar(50) = NULL,
    @p506 nvarchar(50) = NULL,
    @p507 uniqueidentifier = NULL,
    @rowguid40 uniqueidentifier = NULL,
    @setbm40 varbinary(125) = NULL,
    @metadata_type40 tinyint = NULL,
    @lineage_old40 varbinary(311) = NULL,
    @generation40 bigint = NULL,
    @lineage_new40 varbinary(311) = NULL,
    @colv40 varbinary(1) = NULL,
    @p508 varchar(10) = NULL,
    @p509 varchar(10) = NULL,
    @p510 varchar(10) = NULL,
    @p511 nvarchar(50) = NULL,
    @p512 int = NULL,
    @p513 nvarchar(50) = NULL,
    @p514 int = NULL,
    @p515 varchar(50) = NULL,
    @p516 nvarchar(max) = NULL,
    @p517 nvarchar(50) = NULL,
    @p518 nvarchar(50) = NULL,
    @p519 nvarchar(50) = NULL,
    @p520 uniqueidentifier = NULL,
    @rowguid41 uniqueidentifier = NULL,
    @setbm41 varbinary(125) = NULL,
    @metadata_type41 tinyint = NULL,
    @lineage_old41 varbinary(311) = NULL,
    @generation41 bigint = NULL,
    @lineage_new41 varbinary(311) = NULL,
    @colv41 varbinary(1) = NULL,
    @p521 varchar(10) = NULL,
    @p522 varchar(10) = NULL,
    @p523 varchar(10) = NULL,
    @p524 nvarchar(50) = NULL,
    @p525 int = NULL,
    @p526 nvarchar(50) = NULL,
    @p527 int = NULL,
    @p528 varchar(50) = NULL,
    @p529 nvarchar(max) = NULL,
    @p530 nvarchar(50) = NULL,
    @p531 nvarchar(50) = NULL,
    @p532 nvarchar(50) = NULL,
    @p533 uniqueidentifier = NULL,
    @rowguid42 uniqueidentifier = NULL,
    @setbm42 varbinary(125) = NULL,
    @metadata_type42 tinyint = NULL,
    @lineage_old42 varbinary(311) = NULL,
    @generation42 bigint = NULL,
    @lineage_new42 varbinary(311) = NULL,
    @colv42 varbinary(1) = NULL,
    @p534 varchar(10) = NULL,
    @p535 varchar(10) = NULL,
    @p536 varchar(10) = NULL,
    @p537 nvarchar(50) = NULL,
    @p538 int = NULL,
    @p539 nvarchar(50) = NULL,
    @p540 int = NULL,
    @p541 varchar(50) = NULL,
    @p542 nvarchar(max) = NULL,
    @p543 nvarchar(50) = NULL,
    @p544 nvarchar(50) = NULL,
    @p545 nvarchar(50) = NULL,
    @p546 uniqueidentifier = NULL,
    @rowguid43 uniqueidentifier = NULL,
    @setbm43 varbinary(125) = NULL,
    @metadata_type43 tinyint = NULL,
    @lineage_old43 varbinary(311) = NULL,
    @generation43 bigint = NULL,
    @lineage_new43 varbinary(311) = NULL,
    @colv43 varbinary(1) = NULL,
    @p547 varchar(10) = NULL,
    @p548 varchar(10) = NULL,
    @p549 varchar(10) = NULL,
    @p550 nvarchar(50) = NULL,
    @p551 int = NULL,
    @p552 nvarchar(50) = NULL,
    @p553 int = NULL,
    @p554 varchar(50) = NULL,
    @p555 nvarchar(max) = NULL,
    @p556 nvarchar(50) = NULL,
    @p557 nvarchar(50) = NULL,
    @p558 nvarchar(50) = NULL
,
    @p559 uniqueidentifier = NULL,
    @rowguid44 uniqueidentifier = NULL,
    @setbm44 varbinary(125) = NULL,
    @metadata_type44 tinyint = NULL,
    @lineage_old44 varbinary(311) = NULL,
    @generation44 bigint = NULL,
    @lineage_new44 varbinary(311) = NULL,
    @colv44 varbinary(1) = NULL,
    @p560 varchar(10) = NULL,
    @p561 varchar(10) = NULL,
    @p562 varchar(10) = NULL,
    @p563 nvarchar(50) = NULL,
    @p564 int = NULL,
    @p565 nvarchar(50) = NULL,
    @p566 int = NULL,
    @p567 varchar(50) = NULL,
    @p568 nvarchar(max) = NULL,
    @p569 nvarchar(50) = NULL,
    @p570 nvarchar(50) = NULL,
    @p571 nvarchar(50) = NULL,
    @p572 uniqueidentifier = NULL,
    @rowguid45 uniqueidentifier = NULL,
    @setbm45 varbinary(125) = NULL,
    @metadata_type45 tinyint = NULL,
    @lineage_old45 varbinary(311) = NULL,
    @generation45 bigint = NULL,
    @lineage_new45 varbinary(311) = NULL,
    @colv45 varbinary(1) = NULL,
    @p573 varchar(10) = NULL,
    @p574 varchar(10) = NULL,
    @p575 varchar(10) = NULL,
    @p576 nvarchar(50) = NULL,
    @p577 int = NULL,
    @p578 nvarchar(50) = NULL,
    @p579 int = NULL,
    @p580 varchar(50) = NULL,
    @p581 nvarchar(max) = NULL,
    @p582 nvarchar(50) = NULL,
    @p583 nvarchar(50) = NULL,
    @p584 nvarchar(50) = NULL,
    @p585 uniqueidentifier = NULL,
    @rowguid46 uniqueidentifier = NULL,
    @setbm46 varbinary(125) = NULL,
    @metadata_type46 tinyint = NULL,
    @lineage_old46 varbinary(311) = NULL,
    @generation46 bigint = NULL,
    @lineage_new46 varbinary(311) = NULL,
    @colv46 varbinary(1) = NULL,
    @p586 varchar(10) = NULL,
    @p587 varchar(10) = NULL,
    @p588 varchar(10) = NULL,
    @p589 nvarchar(50) = NULL,
    @p590 int = NULL,
    @p591 nvarchar(50) = NULL,
    @p592 int = NULL,
    @p593 varchar(50) = NULL,
    @p594 nvarchar(max) = NULL,
    @p595 nvarchar(50) = NULL,
    @p596 nvarchar(50) = NULL,
    @p597 nvarchar(50) = NULL,
    @p598 uniqueidentifier = NULL,
    @rowguid47 uniqueidentifier = NULL,
    @setbm47 varbinary(125) = NULL,
    @metadata_type47 tinyint = NULL,
    @lineage_old47 varbinary(311) = NULL,
    @generation47 bigint = NULL,
    @lineage_new47 varbinary(311) = NULL,
    @colv47 varbinary(1) = NULL,
    @p599 varchar(10) = NULL,
    @p600 varchar(10) = NULL,
    @p601 varchar(10) = NULL,
    @p602 nvarchar(50) = NULL,
    @p603 int = NULL,
    @p604 nvarchar(50) = NULL,
    @p605 int = NULL,
    @p606 varchar(50) = NULL,
    @p607 nvarchar(max) = NULL,
    @p608 nvarchar(50) = NULL,
    @p609 nvarchar(50) = NULL,
    @p610 nvarchar(50) = NULL,
    @p611 uniqueidentifier = NULL,
    @rowguid48 uniqueidentifier = NULL,
    @setbm48 varbinary(125) = NULL,
    @metadata_type48 tinyint = NULL,
    @lineage_old48 varbinary(311) = NULL,
    @generation48 bigint = NULL,
    @lineage_new48 varbinary(311) = NULL,
    @colv48 varbinary(1) = NULL,
    @p612 varchar(10) = NULL,
    @p613 varchar(10) = NULL,
    @p614 varchar(10) = NULL,
    @p615 nvarchar(50) = NULL,
    @p616 int = NULL,
    @p617 nvarchar(50) = NULL,
    @p618 int = NULL,
    @p619 varchar(50) = NULL,
    @p620 nvarchar(max) = NULL,
    @p621 nvarchar(50) = NULL,
    @p622 nvarchar(50) = NULL,
    @p623 nvarchar(50) = NULL,
    @p624 uniqueidentifier = NULL,
    @rowguid49 uniqueidentifier = NULL,
    @setbm49 varbinary(125) = NULL,
    @metadata_type49 tinyint = NULL,
    @lineage_old49 varbinary(311) = NULL,
    @generation49 bigint = NULL,
    @lineage_new49 varbinary(311) = NULL,
    @colv49 varbinary(1) = NULL,
    @p625 varchar(10) = NULL
,
    @p626 varchar(10) = NULL,
    @p627 varchar(10) = NULL,
    @p628 nvarchar(50) = NULL,
    @p629 int = NULL,
    @p630 nvarchar(50) = NULL,
    @p631 int = NULL,
    @p632 varchar(50) = NULL,
    @p633 nvarchar(max) = NULL,
    @p634 nvarchar(50) = NULL,
    @p635 nvarchar(50) = NULL,
    @p636 nvarchar(50) = NULL,
    @p637 uniqueidentifier = NULL,
    @rowguid50 uniqueidentifier = NULL,
    @setbm50 varbinary(125) = NULL,
    @metadata_type50 tinyint = NULL,
    @lineage_old50 varbinary(311) = NULL,
    @generation50 bigint = NULL,
    @lineage_new50 varbinary(311) = NULL,
    @colv50 varbinary(1) = NULL,
    @p638 varchar(10) = NULL,
    @p639 varchar(10) = NULL,
    @p640 varchar(10) = NULL,
    @p641 nvarchar(50) = NULL,
    @p642 int = NULL,
    @p643 nvarchar(50) = NULL,
    @p644 int = NULL,
    @p645 varchar(50) = NULL,
    @p646 nvarchar(max) = NULL,
    @p647 nvarchar(50) = NULL,
    @p648 nvarchar(50) = NULL,
    @p649 nvarchar(50) = NULL,
    @p650 uniqueidentifier = NULL,
    @rowguid51 uniqueidentifier = NULL,
    @setbm51 varbinary(125) = NULL,
    @metadata_type51 tinyint = NULL,
    @lineage_old51 varbinary(311) = NULL,
    @generation51 bigint = NULL,
    @lineage_new51 varbinary(311) = NULL,
    @colv51 varbinary(1) = NULL,
    @p651 varchar(10) = NULL
,
    @p652 varchar(10) = NULL
,
    @p653 varchar(10) = NULL
,
    @p654 nvarchar(50) = NULL
,
    @p655 int = NULL
,
    @p656 nvarchar(50) = NULL
,
    @p657 int = NULL
,
    @p658 varchar(50) = NULL
,
    @p659 nvarchar(max) = NULL
,
    @p660 nvarchar(50) = NULL
,
    @p661 nvarchar(50) = NULL
,
    @p662 nvarchar(50) = NULL
,
    @p663 uniqueidentifier = NULL

) as
begin
    declare @errcode    int
    declare @retcode    int
    declare @rowcount   int
    declare @error      int
    declare @publication_number smallint
    declare @filtering_column_updated bit
    declare @rows_updated int
    declare @cont_rows_updated int
    declare @rows_in_syncview int
    
    set nocount on
    
    set @errcode= 0
    set @publication_number = 3
    
    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin
        RAISERROR (14126, 11, -1)
        return 4
    end

    if @rows_tobe_updated is NULL or @rows_tobe_updated <=0
        return 0

    select @filtering_column_updated = 0
    select @rows_updated = 0
    select @cont_rows_updated = 0 

    begin tran
    save tran batchupdateproc 

    select @filtering_column_updated = 0

    -- case 1 of setting the filtering column where we are setting it to NULL and the table has a non NULL value for this column
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p1 as c1, @setbm1 as setbm
 union all
            select @rowguid2 as rowguid, @p14 as c1, @setbm2 as setbm
 union all
            select @rowguid3 as rowguid, @p27 as c1, @setbm3 as setbm
 union all
            select @rowguid4 as rowguid, @p40 as c1, @setbm4 as setbm
 union all
            select @rowguid5 as rowguid, @p53 as c1, @setbm5 as setbm
 union all
            select @rowguid6 as rowguid, @p66 as c1, @setbm6 as setbm
 union all
            select @rowguid7 as rowguid, @p79 as c1, @setbm7 as setbm
 union all
            select @rowguid8 as rowguid, @p92 as c1, @setbm8 as setbm
 union all
            select @rowguid9 as rowguid, @p105 as c1, @setbm9 as setbm
 union all
            select @rowguid10 as rowguid, @p118 as c1, @setbm10 as setbm
 union all
            select @rowguid11 as rowguid, @p131 as c1, @setbm11 as setbm
 union all
            select @rowguid12 as rowguid, @p144 as c1, @setbm12 as setbm
 union all
            select @rowguid13 as rowguid, @p157 as c1, @setbm13 as setbm
 union all
            select @rowguid14 as rowguid, @p170 as c1, @setbm14 as setbm
 union all
            select @rowguid15 as rowguid, @p183 as c1, @setbm15 as setbm
 union all
            select @rowguid16 as rowguid, @p196 as c1, @setbm16 as setbm
 union all
            select @rowguid17 as rowguid, @p209 as c1, @setbm17 as setbm
 union all
            select @rowguid18 as rowguid, @p222 as c1, @setbm18 as setbm
 union all
            select @rowguid19 as rowguid, @p235 as c1, @setbm19 as setbm
 union all
            select @rowguid20 as rowguid, @p248 as c1, @setbm20 as setbm
 union all
            select @rowguid21 as rowguid, @p261 as c1, @setbm21 as setbm
 union all
            select @rowguid22 as rowguid, @p274 as c1, @setbm22 as setbm
 union all
            select @rowguid23 as rowguid, @p287 as c1, @setbm23 as setbm
 union all
            select @rowguid24 as rowguid, @p300 as c1, @setbm24 as setbm
 union all
            select @rowguid25 as rowguid, @p313 as c1, @setbm25 as setbm
 union all
            select @rowguid26 as rowguid, @p326 as c1, @setbm26 as setbm
 union all
            select @rowguid27 as rowguid, @p339 as c1, @setbm27 as setbm
 union all
            select @rowguid28 as rowguid, @p352 as c1, @setbm28 as setbm
 union all
            select @rowguid29 as rowguid, @p365 as c1, @setbm29 as setbm
 union all
            select @rowguid30 as rowguid, @p378 as c1, @setbm30 as setbm
 union all
            select @rowguid31 as rowguid, @p391 as c1, @setbm31 as setbm
 union all
            select @rowguid32 as rowguid, @p404 as c1, @setbm32 as setbm
 union all
            select @rowguid33 as rowguid, @p417 as c1, @setbm33 as setbm
 union all
            select @rowguid34 as rowguid, @p430 as c1, @setbm34 as setbm
 union all
            select @rowguid35 as rowguid, @p443 as c1, @setbm35 as setbm
 union all
            select @rowguid36 as rowguid, @p456 as c1, @setbm36 as setbm
 union all
            select @rowguid37 as rowguid, @p469 as c1, @setbm37 as setbm
 union all
            select @rowguid38 as rowguid, @p482 as c1, @setbm38 as setbm
 union all
            select @rowguid39 as rowguid, @p495 as c1, @setbm39 as setbm
 union all
            select @rowguid40 as rowguid, @p508 as c1, @setbm40 as setbm
 union all
            select @rowguid41 as rowguid, @p521 as c1, @setbm41 as setbm
 union all
            select @rowguid42 as rowguid, @p534 as c1, @setbm42 as setbm
 union all
            select @rowguid43 as rowguid, @p547 as c1, @setbm43 as setbm
 union all
            select @rowguid44 as rowguid, @p560 as c1, @setbm44 as setbm
 union all
            select @rowguid45 as rowguid, @p573 as c1, @setbm45 as setbm
 union all
            select @rowguid46 as rowguid, @p586 as c1, @setbm46 as setbm
 union all
            select @rowguid47 as rowguid, @p599 as c1, @setbm47 as setbm
 union all
            select @rowguid48 as rowguid, @p612 as c1, @setbm48 as setbm
 union all
            select @rowguid49 as rowguid, @p625 as c1, @setbm49 as setbm
 union all
            select @rowguid50 as rowguid, @p638 as c1, @setbm50 as setbm
 union all
            select @rowguid51 as rowguid, @p651 as c1, @setbm51 as setbm

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c1 is NULL and sys.fn_IsBitSetInBitmask(rows.setbm, 1) <> 0 and t.[MASP] is not NULL
        
    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MASP]')
        set @errcode=4
        goto Failure
    end

    -- case 2 of setting the filtering column where we are setting it to a not null value and the value is not equal to the value in the table
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p1 as c1
 union all
            select @rowguid2 as rowguid, @p14 as c1
 union all
            select @rowguid3 as rowguid, @p27 as c1
 union all
            select @rowguid4 as rowguid, @p40 as c1
 union all
            select @rowguid5 as rowguid, @p53 as c1
 union all
            select @rowguid6 as rowguid, @p66 as c1
 union all
            select @rowguid7 as rowguid, @p79 as c1
 union all
            select @rowguid8 as rowguid, @p92 as c1
 union all
            select @rowguid9 as rowguid, @p105 as c1
 union all
            select @rowguid10 as rowguid, @p118 as c1
 union all
            select @rowguid11 as rowguid, @p131 as c1
 union all
            select @rowguid12 as rowguid, @p144 as c1
 union all
            select @rowguid13 as rowguid, @p157 as c1
 union all
            select @rowguid14 as rowguid, @p170 as c1
 union all
            select @rowguid15 as rowguid, @p183 as c1
 union all
            select @rowguid16 as rowguid, @p196 as c1
 union all
            select @rowguid17 as rowguid, @p209 as c1
 union all
            select @rowguid18 as rowguid, @p222 as c1
 union all
            select @rowguid19 as rowguid, @p235 as c1
 union all
            select @rowguid20 as rowguid, @p248 as c1
 union all
            select @rowguid21 as rowguid, @p261 as c1
 union all
            select @rowguid22 as rowguid, @p274 as c1
 union all
            select @rowguid23 as rowguid, @p287 as c1
 union all
            select @rowguid24 as rowguid, @p300 as c1
 union all
            select @rowguid25 as rowguid, @p313 as c1
 union all
            select @rowguid26 as rowguid, @p326 as c1
 union all
            select @rowguid27 as rowguid, @p339 as c1
 union all
            select @rowguid28 as rowguid, @p352 as c1
 union all
            select @rowguid29 as rowguid, @p365 as c1
 union all
            select @rowguid30 as rowguid, @p378 as c1
 union all
            select @rowguid31 as rowguid, @p391 as c1
 union all
            select @rowguid32 as rowguid, @p404 as c1
 union all
            select @rowguid33 as rowguid, @p417 as c1
 union all
            select @rowguid34 as rowguid, @p430 as c1
 union all
            select @rowguid35 as rowguid, @p443 as c1
 union all
            select @rowguid36 as rowguid, @p456 as c1
 union all
            select @rowguid37 as rowguid, @p469 as c1
 union all
            select @rowguid38 as rowguid, @p482 as c1
 union all
            select @rowguid39 as rowguid, @p495 as c1
 union all
            select @rowguid40 as rowguid, @p508 as c1
 union all
            select @rowguid41 as rowguid, @p521 as c1
 union all
            select @rowguid42 as rowguid, @p534 as c1
 union all
            select @rowguid43 as rowguid, @p547 as c1
 union all
            select @rowguid44 as rowguid, @p560 as c1
 union all
            select @rowguid45 as rowguid, @p573 as c1
 union all
            select @rowguid46 as rowguid, @p586 as c1
 union all
            select @rowguid47 as rowguid, @p599 as c1
 union all
            select @rowguid48 as rowguid, @p612 as c1
 union all
            select @rowguid49 as rowguid, @p625 as c1
 union all
            select @rowguid50 as rowguid, @p638 as c1
 union all
            select @rowguid51 as rowguid, @p651 as c1

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c1 is not NULL and (t.[MASP] is NULL or t.[MASP] <> rows.c1 )   

    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MASP]')
        set @errcode=4
        goto Failure
    end

    select @filtering_column_updated = 0

    -- case 1 of setting the filtering column where we are setting it to NULL and the table has a non NULL value for this column
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p2 as c2, @setbm1 as setbm
 union all
            select @rowguid2 as rowguid, @p15 as c2, @setbm2 as setbm
 union all
            select @rowguid3 as rowguid, @p28 as c2, @setbm3 as setbm
 union all
            select @rowguid4 as rowguid, @p41 as c2, @setbm4 as setbm
 union all
            select @rowguid5 as rowguid, @p54 as c2, @setbm5 as setbm
 union all
            select @rowguid6 as rowguid, @p67 as c2, @setbm6 as setbm
 union all
            select @rowguid7 as rowguid, @p80 as c2, @setbm7 as setbm
 union all
            select @rowguid8 as rowguid, @p93 as c2, @setbm8 as setbm
 union all
            select @rowguid9 as rowguid, @p106 as c2, @setbm9 as setbm
 union all
            select @rowguid10 as rowguid, @p119 as c2, @setbm10 as setbm
 union all
            select @rowguid11 as rowguid, @p132 as c2, @setbm11 as setbm
 union all
            select @rowguid12 as rowguid, @p145 as c2, @setbm12 as setbm
 union all
            select @rowguid13 as rowguid, @p158 as c2, @setbm13 as setbm
 union all
            select @rowguid14 as rowguid, @p171 as c2, @setbm14 as setbm
 union all
            select @rowguid15 as rowguid, @p184 as c2, @setbm15 as setbm
 union all
            select @rowguid16 as rowguid, @p197 as c2, @setbm16 as setbm
 union all
            select @rowguid17 as rowguid, @p210 as c2, @setbm17 as setbm
 union all
            select @rowguid18 as rowguid, @p223 as c2, @setbm18 as setbm
 union all
            select @rowguid19 as rowguid, @p236 as c2, @setbm19 as setbm
 union all
            select @rowguid20 as rowguid, @p249 as c2, @setbm20 as setbm
 union all
            select @rowguid21 as rowguid, @p262 as c2, @setbm21 as setbm
 union all
            select @rowguid22 as rowguid, @p275 as c2, @setbm22 as setbm
 union all
            select @rowguid23 as rowguid, @p288 as c2, @setbm23 as setbm
 union all
            select @rowguid24 as rowguid, @p301 as c2, @setbm24 as setbm
 union all
            select @rowguid25 as rowguid, @p314 as c2, @setbm25 as setbm
 union all
            select @rowguid26 as rowguid, @p327 as c2, @setbm26 as setbm
 union all
            select @rowguid27 as rowguid, @p340 as c2, @setbm27 as setbm
 union all
            select @rowguid28 as rowguid, @p353 as c2, @setbm28 as setbm
 union all
            select @rowguid29 as rowguid, @p366 as c2, @setbm29 as setbm
 union all
            select @rowguid30 as rowguid, @p379 as c2, @setbm30 as setbm
 union all
            select @rowguid31 as rowguid, @p392 as c2, @setbm31 as setbm
 union all
            select @rowguid32 as rowguid, @p405 as c2, @setbm32 as setbm
 union all
            select @rowguid33 as rowguid, @p418 as c2, @setbm33 as setbm
 union all
            select @rowguid34 as rowguid, @p431 as c2, @setbm34 as setbm
 union all
            select @rowguid35 as rowguid, @p444 as c2, @setbm35 as setbm
 union all
            select @rowguid36 as rowguid, @p457 as c2, @setbm36 as setbm
 union all
            select @rowguid37 as rowguid, @p470 as c2, @setbm37 as setbm
 union all
            select @rowguid38 as rowguid, @p483 as c2, @setbm38 as setbm
 union all
            select @rowguid39 as rowguid, @p496 as c2, @setbm39 as setbm
 union all
            select @rowguid40 as rowguid, @p509 as c2, @setbm40 as setbm
 union all
            select @rowguid41 as rowguid, @p522 as c2, @setbm41 as setbm
 union all
            select @rowguid42 as rowguid, @p535 as c2, @setbm42 as setbm
 union all
            select @rowguid43 as rowguid, @p548 as c2, @setbm43 as setbm
 union all
            select @rowguid44 as rowguid, @p561 as c2, @setbm44 as setbm
 union all
            select @rowguid45 as rowguid, @p574 as c2, @setbm45 as setbm
 union all
            select @rowguid46 as rowguid, @p587 as c2, @setbm46 as setbm
 union all
            select @rowguid47 as rowguid, @p600 as c2, @setbm47 as setbm
 union all
            select @rowguid48 as rowguid, @p613 as c2, @setbm48 as setbm
 union all
            select @rowguid49 as rowguid, @p626 as c2, @setbm49 as setbm
 union all
            select @rowguid50 as rowguid, @p639 as c2, @setbm50 as setbm
 union all
            select @rowguid51 as rowguid, @p652 as c2, @setbm51 as setbm

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c2 is NULL and sys.fn_IsBitSetInBitmask(rows.setbm, 2) <> 0 and t.[MANCC] is not NULL
        
    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MANCC]')
        set @errcode=4
        goto Failure
    end

    -- case 2 of setting the filtering column where we are setting it to a not null value and the value is not equal to the value in the table
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p2 as c2
 union all
            select @rowguid2 as rowguid, @p15 as c2
 union all
            select @rowguid3 as rowguid, @p28 as c2
 union all
            select @rowguid4 as rowguid, @p41 as c2
 union all
            select @rowguid5 as rowguid, @p54 as c2
 union all
            select @rowguid6 as rowguid, @p67 as c2
 union all
            select @rowguid7 as rowguid, @p80 as c2
 union all
            select @rowguid8 as rowguid, @p93 as c2
 union all
            select @rowguid9 as rowguid, @p106 as c2
 union all
            select @rowguid10 as rowguid, @p119 as c2
 union all
            select @rowguid11 as rowguid, @p132 as c2
 union all
            select @rowguid12 as rowguid, @p145 as c2
 union all
            select @rowguid13 as rowguid, @p158 as c2
 union all
            select @rowguid14 as rowguid, @p171 as c2
 union all
            select @rowguid15 as rowguid, @p184 as c2
 union all
            select @rowguid16 as rowguid, @p197 as c2
 union all
            select @rowguid17 as rowguid, @p210 as c2
 union all
            select @rowguid18 as rowguid, @p223 as c2
 union all
            select @rowguid19 as rowguid, @p236 as c2
 union all
            select @rowguid20 as rowguid, @p249 as c2
 union all
            select @rowguid21 as rowguid, @p262 as c2
 union all
            select @rowguid22 as rowguid, @p275 as c2
 union all
            select @rowguid23 as rowguid, @p288 as c2
 union all
            select @rowguid24 as rowguid, @p301 as c2
 union all
            select @rowguid25 as rowguid, @p314 as c2
 union all
            select @rowguid26 as rowguid, @p327 as c2
 union all
            select @rowguid27 as rowguid, @p340 as c2
 union all
            select @rowguid28 as rowguid, @p353 as c2
 union all
            select @rowguid29 as rowguid, @p366 as c2
 union all
            select @rowguid30 as rowguid, @p379 as c2
 union all
            select @rowguid31 as rowguid, @p392 as c2
 union all
            select @rowguid32 as rowguid, @p405 as c2
 union all
            select @rowguid33 as rowguid, @p418 as c2
 union all
            select @rowguid34 as rowguid, @p431 as c2
 union all
            select @rowguid35 as rowguid, @p444 as c2
 union all
            select @rowguid36 as rowguid, @p457 as c2
 union all
            select @rowguid37 as rowguid, @p470 as c2
 union all
            select @rowguid38 as rowguid, @p483 as c2
 union all
            select @rowguid39 as rowguid, @p496 as c2
 union all
            select @rowguid40 as rowguid, @p509 as c2
 union all
            select @rowguid41 as rowguid, @p522 as c2
 union all
            select @rowguid42 as rowguid, @p535 as c2
 union all
            select @rowguid43 as rowguid, @p548 as c2
 union all
            select @rowguid44 as rowguid, @p561 as c2
 union all
            select @rowguid45 as rowguid, @p574 as c2
 union all
            select @rowguid46 as rowguid, @p587 as c2
 union all
            select @rowguid47 as rowguid, @p600 as c2
 union all
            select @rowguid48 as rowguid, @p613 as c2
 union all
            select @rowguid49 as rowguid, @p626 as c2
 union all
            select @rowguid50 as rowguid, @p639 as c2
 union all
            select @rowguid51 as rowguid, @p652 as c2

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c2 is not NULL and (t.[MANCC] is NULL or t.[MANCC] <> rows.c2 )   

    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MANCC]')
        set @errcode=4
        goto Failure
    end

    select @filtering_column_updated = 0

    -- case 1 of setting the filtering column where we are setting it to NULL and the table has a non NULL value for this column
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p3 as c3, @setbm1 as setbm
 union all
            select @rowguid2 as rowguid, @p16 as c3, @setbm2 as setbm
 union all
            select @rowguid3 as rowguid, @p29 as c3, @setbm3 as setbm
 union all
            select @rowguid4 as rowguid, @p42 as c3, @setbm4 as setbm
 union all
            select @rowguid5 as rowguid, @p55 as c3, @setbm5 as setbm
 union all
            select @rowguid6 as rowguid, @p68 as c3, @setbm6 as setbm
 union all
            select @rowguid7 as rowguid, @p81 as c3, @setbm7 as setbm
 union all
            select @rowguid8 as rowguid, @p94 as c3, @setbm8 as setbm
 union all
            select @rowguid9 as rowguid, @p107 as c3, @setbm9 as setbm
 union all
            select @rowguid10 as rowguid, @p120 as c3, @setbm10 as setbm
 union all
            select @rowguid11 as rowguid, @p133 as c3, @setbm11 as setbm
 union all
            select @rowguid12 as rowguid, @p146 as c3, @setbm12 as setbm
 union all
            select @rowguid13 as rowguid, @p159 as c3, @setbm13 as setbm
 union all
            select @rowguid14 as rowguid, @p172 as c3, @setbm14 as setbm
 union all
            select @rowguid15 as rowguid, @p185 as c3, @setbm15 as setbm
 union all
            select @rowguid16 as rowguid, @p198 as c3, @setbm16 as setbm
 union all
            select @rowguid17 as rowguid, @p211 as c3, @setbm17 as setbm
 union all
            select @rowguid18 as rowguid, @p224 as c3, @setbm18 as setbm
 union all
            select @rowguid19 as rowguid, @p237 as c3, @setbm19 as setbm
 union all
            select @rowguid20 as rowguid, @p250 as c3, @setbm20 as setbm
 union all
            select @rowguid21 as rowguid, @p263 as c3, @setbm21 as setbm
 union all
            select @rowguid22 as rowguid, @p276 as c3, @setbm22 as setbm
 union all
            select @rowguid23 as rowguid, @p289 as c3, @setbm23 as setbm
 union all
            select @rowguid24 as rowguid, @p302 as c3, @setbm24 as setbm
 union all
            select @rowguid25 as rowguid, @p315 as c3, @setbm25 as setbm
 union all
            select @rowguid26 as rowguid, @p328 as c3, @setbm26 as setbm
 union all
            select @rowguid27 as rowguid, @p341 as c3, @setbm27 as setbm
 union all
            select @rowguid28 as rowguid, @p354 as c3, @setbm28 as setbm
 union all
            select @rowguid29 as rowguid, @p367 as c3, @setbm29 as setbm
 union all
            select @rowguid30 as rowguid, @p380 as c3, @setbm30 as setbm
 union all
            select @rowguid31 as rowguid, @p393 as c3, @setbm31 as setbm
 union all
            select @rowguid32 as rowguid, @p406 as c3, @setbm32 as setbm
 union all
            select @rowguid33 as rowguid, @p419 as c3, @setbm33 as setbm
 union all
            select @rowguid34 as rowguid, @p432 as c3, @setbm34 as setbm
 union all
            select @rowguid35 as rowguid, @p445 as c3, @setbm35 as setbm
 union all
            select @rowguid36 as rowguid, @p458 as c3, @setbm36 as setbm
 union all
            select @rowguid37 as rowguid, @p471 as c3, @setbm37 as setbm
 union all
            select @rowguid38 as rowguid, @p484 as c3, @setbm38 as setbm
 union all
            select @rowguid39 as rowguid, @p497 as c3, @setbm39 as setbm
 union all
            select @rowguid40 as rowguid, @p510 as c3, @setbm40 as setbm
 union all
            select @rowguid41 as rowguid, @p523 as c3, @setbm41 as setbm
 union all
            select @rowguid42 as rowguid, @p536 as c3, @setbm42 as setbm
 union all
            select @rowguid43 as rowguid, @p549 as c3, @setbm43 as setbm
 union all
            select @rowguid44 as rowguid, @p562 as c3, @setbm44 as setbm
 union all
            select @rowguid45 as rowguid, @p575 as c3, @setbm45 as setbm
 union all
            select @rowguid46 as rowguid, @p588 as c3, @setbm46 as setbm
 union all
            select @rowguid47 as rowguid, @p601 as c3, @setbm47 as setbm
 union all
            select @rowguid48 as rowguid, @p614 as c3, @setbm48 as setbm
 union all
            select @rowguid49 as rowguid, @p627 as c3, @setbm49 as setbm
 union all
            select @rowguid50 as rowguid, @p640 as c3, @setbm50 as setbm
 union all
            select @rowguid51 as rowguid, @p653 as c3, @setbm51 as setbm

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c3 is NULL and sys.fn_IsBitSetInBitmask(rows.setbm, 3) <> 0 and t.[MALOAI] is not NULL
        
    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MALOAI]')
        set @errcode=4
        goto Failure
    end

    -- case 2 of setting the filtering column where we are setting it to a not null value and the value is not equal to the value in the table
    select @filtering_column_updated = 1 from 
        (

            select @rowguid1 as rowguid, @p3 as c3
 union all
            select @rowguid2 as rowguid, @p16 as c3
 union all
            select @rowguid3 as rowguid, @p29 as c3
 union all
            select @rowguid4 as rowguid, @p42 as c3
 union all
            select @rowguid5 as rowguid, @p55 as c3
 union all
            select @rowguid6 as rowguid, @p68 as c3
 union all
            select @rowguid7 as rowguid, @p81 as c3
 union all
            select @rowguid8 as rowguid, @p94 as c3
 union all
            select @rowguid9 as rowguid, @p107 as c3
 union all
            select @rowguid10 as rowguid, @p120 as c3
 union all
            select @rowguid11 as rowguid, @p133 as c3
 union all
            select @rowguid12 as rowguid, @p146 as c3
 union all
            select @rowguid13 as rowguid, @p159 as c3
 union all
            select @rowguid14 as rowguid, @p172 as c3
 union all
            select @rowguid15 as rowguid, @p185 as c3
 union all
            select @rowguid16 as rowguid, @p198 as c3
 union all
            select @rowguid17 as rowguid, @p211 as c3
 union all
            select @rowguid18 as rowguid, @p224 as c3
 union all
            select @rowguid19 as rowguid, @p237 as c3
 union all
            select @rowguid20 as rowguid, @p250 as c3
 union all
            select @rowguid21 as rowguid, @p263 as c3
 union all
            select @rowguid22 as rowguid, @p276 as c3
 union all
            select @rowguid23 as rowguid, @p289 as c3
 union all
            select @rowguid24 as rowguid, @p302 as c3
 union all
            select @rowguid25 as rowguid, @p315 as c3
 union all
            select @rowguid26 as rowguid, @p328 as c3
 union all
            select @rowguid27 as rowguid, @p341 as c3
 union all
            select @rowguid28 as rowguid, @p354 as c3
 union all
            select @rowguid29 as rowguid, @p367 as c3
 union all
            select @rowguid30 as rowguid, @p380 as c3
 union all
            select @rowguid31 as rowguid, @p393 as c3
 union all
            select @rowguid32 as rowguid, @p406 as c3
 union all
            select @rowguid33 as rowguid, @p419 as c3
 union all
            select @rowguid34 as rowguid, @p432 as c3
 union all
            select @rowguid35 as rowguid, @p445 as c3
 union all
            select @rowguid36 as rowguid, @p458 as c3
 union all
            select @rowguid37 as rowguid, @p471 as c3
 union all
            select @rowguid38 as rowguid, @p484 as c3
 union all
            select @rowguid39 as rowguid, @p497 as c3
 union all
            select @rowguid40 as rowguid, @p510 as c3
 union all
            select @rowguid41 as rowguid, @p523 as c3
 union all
            select @rowguid42 as rowguid, @p536 as c3
 union all
            select @rowguid43 as rowguid, @p549 as c3
 union all
            select @rowguid44 as rowguid, @p562 as c3
 union all
            select @rowguid45 as rowguid, @p575 as c3
 union all
            select @rowguid46 as rowguid, @p588 as c3
 union all
            select @rowguid47 as rowguid, @p601 as c3
 union all
            select @rowguid48 as rowguid, @p614 as c3
 union all
            select @rowguid49 as rowguid, @p627 as c3
 union all
            select @rowguid50 as rowguid, @p640 as c3
 union all
            select @rowguid51 as rowguid, @p653 as c3

        ) as rows
        inner join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid and rows.rowguid is not NULL
        where rows.c3 is not NULL and (t.[MALOAI] is NULL or t.[MALOAI] <> rows.c3 )   

    if @filtering_column_updated = 1
    begin
        raiserror(20694, 16, -1, 'SANPHAM', '[MALOAI]')
        set @errcode=4
        goto Failure
    end

    update [dbo].[SANPHAM] with (rowlock)
    set 

        [TENSP] = case when rows.c4 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 4) <> 0 then rows.c4 else t.[TENSP] end) else rows.c4 end 
,
        [DONGIA] = case when rows.c5 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 5) <> 0 then rows.c5 else t.[DONGIA] end) else rows.c5 end 
,
        [DVT] = case when rows.c6 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 6) <> 0 then rows.c6 else t.[DVT] end) else rows.c6 end 
,
        [SOLUONG] = case when rows.c7 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 7) <> 0 then rows.c7 else t.[SOLUONG] end) else rows.c7 end 
,
        [ANH] = case when rows.c8 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 8) <> 0 then rows.c8 else t.[ANH] end) else rows.c8 end 
,
        [MOTA] = case when rows.c9 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 9) <> 0 then rows.c9 else t.[MOTA] end) else rows.c9 end 
,
        [KICHTHUOC] = case when rows.c10 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 10) <> 0 then rows.c10 else t.[KICHTHUOC] end) else rows.c10 end 
,
        [TRONGLUONG] = case when rows.c11 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 11) <> 0 then rows.c11 else t.[TRONGLUONG] end) else rows.c11 end 
,
        [MAUSAC] = case when rows.c12 is NULL then (case when sys.fn_IsBitSetInBitmask(rows.setbm, 12) <> 0 then rows.c12 else t.[MAUSAC] end) else rows.c12 end 

    from (

    select @rowguid1 as rowguid, @setbm1 as setbm, @metadata_type1 as metadata_type, @lineage_old1 as lineage_old, @p4 as c4, @p5 as c5, @p6 as c6, @p7 as c7, @p8 as c8, @p9 as c9, 
            @p10 as c10, @p11 as c11, @p12 as c12 union all
    select @rowguid2 as rowguid, @setbm2 as setbm, @metadata_type2 as metadata_type, @lineage_old2 as lineage_old, @p17 as c4, @p18 as c5, @p19 as c6, @p20 as c7, @p21 as c8, @p22 as c9, 
            @p23 as c10, @p24 as c11, @p25 as c12 union all
    select @rowguid3 as rowguid, @setbm3 as setbm, @metadata_type3 as metadata_type, @lineage_old3 as lineage_old, @p30 as c4, @p31 as c5, @p32 as c6, @p33 as c7, @p34 as c8, @p35 as c9, 
            @p36 as c10, @p37 as c11, @p38 as c12 union all
    select @rowguid4 as rowguid, @setbm4 as setbm, @metadata_type4 as metadata_type, @lineage_old4 as lineage_old, @p43 as c4, @p44 as c5, @p45 as c6, @p46 as c7, @p47 as c8, @p48 as c9, 
            @p49 as c10, @p50 as c11, @p51 as c12 union all
    select @rowguid5 as rowguid, @setbm5 as setbm, @metadata_type5 as metadata_type, @lineage_old5 as lineage_old, @p56 as c4, @p57 as c5, @p58 as c6, @p59 as c7, @p60 as c8, @p61 as c9, 
            @p62 as c10, @p63 as c11, @p64 as c12 union all
    select @rowguid6 as rowguid, @setbm6 as setbm, @metadata_type6 as metadata_type, @lineage_old6 as lineage_old, @p69 as c4, @p70 as c5, @p71 as c6, @p72 as c7, @p73 as c8, @p74 as c9, 
            @p75 as c10, @p76 as c11, @p77 as c12 union all
    select @rowguid7 as rowguid, @setbm7 as setbm, @metadata_type7 as metadata_type, @lineage_old7 as lineage_old, @p82 as c4, @p83 as c5, @p84 as c6, @p85 as c7, @p86 as c8, @p87 as c9, 
            @p88 as c10, @p89 as c11, @p90 as c12 union all
    select @rowguid8 as rowguid, @setbm8 as setbm, @metadata_type8 as metadata_type, @lineage_old8 as lineage_old, @p95 as c4, @p96 as c5, @p97 as c6, @p98 as c7, @p99 as c8, @p100 as c9, 
            @p101 as c10, @p102 as c11, @p103 as c12 union all
    select @rowguid9 as rowguid, @setbm9 as setbm, @metadata_type9 as metadata_type, @lineage_old9 as lineage_old, @p108 as c4, @p109 as c5, @p110 as c6, @p111 as c7, @p112 as c8, @p113 as c9, 
            @p114 as c10, @p115 as c11, @p116 as c12 union all
    select @rowguid10 as rowguid, @setbm10 as setbm, @metadata_type10 as metadata_type, @lineage_old10 as lineage_old, @p121 as c4, @p122 as c5, @p123 as c6, @p124 as c7, @p125 as c8, @p126 as c9, 
            @p127 as c10, @p128 as c11, @p129 as c12 union all
    select @rowguid11 as rowguid, @setbm11 as setbm, @metadata_type11 as metadata_type, @lineage_old11 as lineage_old, @p134 as c4, @p135 as c5, @p136 as c6, @p137 as c7, @p138 as c8, @p139 as c9, 
            @p140 as c10, @p141 as c11, @p142 as c12 union all
    select @rowguid12 as rowguid, @setbm12 as setbm, @metadata_type12 as metadata_type, @lineage_old12 as lineage_old, @p147 as c4, @p148 as c5, @p149 as c6, @p150 as c7, @p151 as c8, @p152 as c9, 
            @p153 as c10, @p154 as c11, @p155 as c12 union all
    select @rowguid13 as rowguid, @setbm13 as setbm, @metadata_type13 as metadata_type, @lineage_old13 as lineage_old, @p160 as c4, @p161 as c5, @p162 as c6, @p163 as c7, @p164 as c8, @p165 as c9, 
            @p166 as c10, @p167 as c11, @p168 as c12 union all
    select @rowguid14 as rowguid, @setbm14 as setbm, @metadata_type14 as metadata_type, @lineage_old14 as lineage_old, @p173 as c4, @p174 as c5, @p175 as c6, @p176 as c7, @p177 as c8, @p178 as c9, 
            @p179 as c10, @p180 as c11, @p181 as c12 union all
    select @rowguid15 as rowguid, @setbm15 as setbm, @metadata_type15 as metadata_type, @lineage_old15 as lineage_old, @p186 as c4, @p187 as c5, @p188 as c6, @p189 as c7, @p190 as c8
, @p191 as c9, 
            @p192 as c10, @p193 as c11, @p194 as c12 union all
    select @rowguid16 as rowguid, @setbm16 as setbm, @metadata_type16 as metadata_type, @lineage_old16 as lineage_old, @p199 as c4, @p200 as c5, @p201 as c6, @p202 as c7, @p203 as c8, @p204 as c9, 
            @p205 as c10, @p206 as c11, @p207 as c12 union all
    select @rowguid17 as rowguid, @setbm17 as setbm, @metadata_type17 as metadata_type, @lineage_old17 as lineage_old, @p212 as c4, @p213 as c5, @p214 as c6, @p215 as c7, @p216 as c8, @p217 as c9, 
            @p218 as c10, @p219 as c11, @p220 as c12 union all
    select @rowguid18 as rowguid, @setbm18 as setbm, @metadata_type18 as metadata_type, @lineage_old18 as lineage_old, @p225 as c4, @p226 as c5, @p227 as c6, @p228 as c7, @p229 as c8, @p230 as c9, 
            @p231 as c10, @p232 as c11, @p233 as c12 union all
    select @rowguid19 as rowguid, @setbm19 as setbm, @metadata_type19 as metadata_type, @lineage_old19 as lineage_old, @p238 as c4, @p239 as c5, @p240 as c6, @p241 as c7, @p242 as c8, @p243 as c9, 
            @p244 as c10, @p245 as c11, @p246 as c12 union all
    select @rowguid20 as rowguid, @setbm20 as setbm, @metadata_type20 as metadata_type, @lineage_old20 as lineage_old, @p251 as c4, @p252 as c5, @p253 as c6, @p254 as c7, @p255 as c8, @p256 as c9, 
            @p257 as c10, @p258 as c11, @p259 as c12 union all
    select @rowguid21 as rowguid, @setbm21 as setbm, @metadata_type21 as metadata_type, @lineage_old21 as lineage_old, @p264 as c4, @p265 as c5, @p266 as c6, @p267 as c7, @p268 as c8, @p269 as c9, 
            @p270 as c10, @p271 as c11, @p272 as c12 union all
    select @rowguid22 as rowguid, @setbm22 as setbm, @metadata_type22 as metadata_type, @lineage_old22 as lineage_old, @p277 as c4, @p278 as c5, @p279 as c6, @p280 as c7, @p281 as c8, @p282 as c9, 
            @p283 as c10, @p284 as c11, @p285 as c12 union all
    select @rowguid23 as rowguid, @setbm23 as setbm, @metadata_type23 as metadata_type, @lineage_old23 as lineage_old, @p290 as c4, @p291 as c5, @p292 as c6, @p293 as c7, @p294 as c8, @p295 as c9, 
            @p296 as c10, @p297 as c11, @p298 as c12 union all
    select @rowguid24 as rowguid, @setbm24 as setbm, @metadata_type24 as metadata_type, @lineage_old24 as lineage_old, @p303 as c4, @p304 as c5, @p305 as c6, @p306 as c7, @p307 as c8, @p308 as c9, 
            @p309 as c10, @p310 as c11, @p311 as c12 union all
    select @rowguid25 as rowguid, @setbm25 as setbm, @metadata_type25 as metadata_type, @lineage_old25 as lineage_old, @p316 as c4, @p317 as c5, @p318 as c6, @p319 as c7, @p320 as c8, @p321 as c9, 
            @p322 as c10, @p323 as c11, @p324 as c12 union all
    select @rowguid26 as rowguid, @setbm26 as setbm, @metadata_type26 as metadata_type, @lineage_old26 as lineage_old, @p329 as c4, @p330 as c5, @p331 as c6, @p332 as c7, @p333 as c8, @p334 as c9, 
            @p335 as c10, @p336 as c11, @p337 as c12 union all
    select @rowguid27 as rowguid, @setbm27 as setbm, @metadata_type27 as metadata_type, @lineage_old27 as lineage_old, @p342 as c4, @p343 as c5, @p344 as c6, @p345 as c7, @p346 as c8, @p347 as c9, 
            @p348 as c10, @p349 as c11, @p350 as c12 union all
    select @rowguid28 as rowguid, @setbm28 as setbm, @metadata_type28 as metadata_type, @lineage_old28 as lineage_old, @p355 as c4, @p356 as c5, @p357 as c6, @p358 as c7, @p359 as c8, @p360 as c9, 
            @p361 as c10, @p362 as c11, @p363 as c12 union all
    select @rowguid29 as rowguid, @setbm29 as setbm, @metadata_type29 as metadata_type, @lineage_old29 as lineage_old, @p368 as c4, @p369 as c5, @p370 as c6, @p371 as c7, @p372 as c8, @p373 as c9, 
            @p374 as c10, @p375 as c11, @p376 as c12
 union all
    select @rowguid30 as rowguid, @setbm30 as setbm, @metadata_type30 as metadata_type, @lineage_old30 as lineage_old, @p381 as c4, @p382 as c5, @p383 as c6, @p384 as c7, @p385 as c8, @p386 as c9, 
            @p387 as c10, @p388 as c11, @p389 as c12 union all
    select @rowguid31 as rowguid, @setbm31 as setbm, @metadata_type31 as metadata_type, @lineage_old31 as lineage_old, @p394 as c4, @p395 as c5, @p396 as c6, @p397 as c7, @p398 as c8, @p399 as c9, 
            @p400 as c10, @p401 as c11, @p402 as c12 union all
    select @rowguid32 as rowguid, @setbm32 as setbm, @metadata_type32 as metadata_type, @lineage_old32 as lineage_old, @p407 as c4, @p408 as c5, @p409 as c6, @p410 as c7, @p411 as c8, @p412 as c9, 
            @p413 as c10, @p414 as c11, @p415 as c12 union all
    select @rowguid33 as rowguid, @setbm33 as setbm, @metadata_type33 as metadata_type, @lineage_old33 as lineage_old, @p420 as c4, @p421 as c5, @p422 as c6, @p423 as c7, @p424 as c8, @p425 as c9, 
            @p426 as c10, @p427 as c11, @p428 as c12 union all
    select @rowguid34 as rowguid, @setbm34 as setbm, @metadata_type34 as metadata_type, @lineage_old34 as lineage_old, @p433 as c4, @p434 as c5, @p435 as c6, @p436 as c7, @p437 as c8, @p438 as c9, 
            @p439 as c10, @p440 as c11, @p441 as c12 union all
    select @rowguid35 as rowguid, @setbm35 as setbm, @metadata_type35 as metadata_type, @lineage_old35 as lineage_old, @p446 as c4, @p447 as c5, @p448 as c6, @p449 as c7, @p450 as c8, @p451 as c9, 
            @p452 as c10, @p453 as c11, @p454 as c12 union all
    select @rowguid36 as rowguid, @setbm36 as setbm, @metadata_type36 as metadata_type, @lineage_old36 as lineage_old, @p459 as c4, @p460 as c5, @p461 as c6, @p462 as c7, @p463 as c8, @p464 as c9, 
            @p465 as c10, @p466 as c11, @p467 as c12 union all
    select @rowguid37 as rowguid, @setbm37 as setbm, @metadata_type37 as metadata_type, @lineage_old37 as lineage_old, @p472 as c4, @p473 as c5, @p474 as c6, @p475 as c7, @p476 as c8, @p477 as c9, 
            @p478 as c10, @p479 as c11, @p480 as c12 union all
    select @rowguid38 as rowguid, @setbm38 as setbm, @metadata_type38 as metadata_type, @lineage_old38 as lineage_old, @p485 as c4, @p486 as c5, @p487 as c6, @p488 as c7, @p489 as c8, @p490 as c9, 
            @p491 as c10, @p492 as c11, @p493 as c12 union all
    select @rowguid39 as rowguid, @setbm39 as setbm, @metadata_type39 as metadata_type, @lineage_old39 as lineage_old, @p498 as c4, @p499 as c5, @p500 as c6, @p501 as c7, @p502 as c8, @p503 as c9, 
            @p504 as c10, @p505 as c11, @p506 as c12 union all
    select @rowguid40 as rowguid, @setbm40 as setbm, @metadata_type40 as metadata_type, @lineage_old40 as lineage_old, @p511 as c4, @p512 as c5, @p513 as c6, @p514 as c7, @p515 as c8, @p516 as c9, 
            @p517 as c10, @p518 as c11, @p519 as c12 union all
    select @rowguid41 as rowguid, @setbm41 as setbm, @metadata_type41 as metadata_type, @lineage_old41 as lineage_old, @p524 as c4, @p525 as c5, @p526 as c6, @p527 as c7, @p528 as c8, @p529 as c9, 
            @p530 as c10, @p531 as c11, @p532 as c12 union all
    select @rowguid42 as rowguid, @setbm42 as setbm, @metadata_type42 as metadata_type, @lineage_old42 as lineage_old, @p537 as c4, @p538 as c5, @p539 as c6, @p540 as c7, @p541 as c8, @p542 as c9, 
            @p543 as c10, @p544 as c11, @p545 as c12 union all
    select @rowguid43 as rowguid, @setbm43 as setbm, @metadata_type43 as metadata_type, @lineage_old43 as lineage_old, @p550 as c4, @p551 as c5, @p552 as c6, @p553 as c7, @p554 as c8, @p555 as c9, 
            @p556 as c10, @p557 as c11, @p558 as c12 union all
    select @rowguid44 as rowguid, @setbm44 as setbm, @metadata_type44 as metadata_type, @lineage_old44 as lineage_old, @p563 as c4
, @p564 as c5, @p565 as c6, @p566 as c7, @p567 as c8, @p568 as c9, 
            @p569 as c10, @p570 as c11, @p571 as c12 union all
    select @rowguid45 as rowguid, @setbm45 as setbm, @metadata_type45 as metadata_type, @lineage_old45 as lineage_old, @p576 as c4, @p577 as c5, @p578 as c6, @p579 as c7, @p580 as c8, @p581 as c9, 
            @p582 as c10, @p583 as c11, @p584 as c12 union all
    select @rowguid46 as rowguid, @setbm46 as setbm, @metadata_type46 as metadata_type, @lineage_old46 as lineage_old, @p589 as c4, @p590 as c5, @p591 as c6, @p592 as c7, @p593 as c8, @p594 as c9, 
            @p595 as c10, @p596 as c11, @p597 as c12 union all
    select @rowguid47 as rowguid, @setbm47 as setbm, @metadata_type47 as metadata_type, @lineage_old47 as lineage_old, @p602 as c4, @p603 as c5, @p604 as c6, @p605 as c7, @p606 as c8, @p607 as c9, 
            @p608 as c10, @p609 as c11, @p610 as c12 union all
    select @rowguid48 as rowguid, @setbm48 as setbm, @metadata_type48 as metadata_type, @lineage_old48 as lineage_old, @p615 as c4, @p616 as c5, @p617 as c6, @p618 as c7, @p619 as c8, @p620 as c9, 
            @p621 as c10, @p622 as c11, @p623 as c12 union all
    select @rowguid49 as rowguid, @setbm49 as setbm, @metadata_type49 as metadata_type, @lineage_old49 as lineage_old, @p628 as c4, @p629 as c5, @p630 as c6, @p631 as c7, @p632 as c8, @p633 as c9, 
            @p634 as c10, @p635 as c11, @p636 as c12 union all
    select @rowguid50 as rowguid, @setbm50 as setbm, @metadata_type50 as metadata_type, @lineage_old50 as lineage_old, @p641 as c4, @p642 as c5, @p643 as c6, @p644 as c7, @p645 as c8, @p646 as c9, 
            @p647 as c10, @p648 as c11, @p649 as c12 union all
    select @rowguid51 as rowguid, @setbm51 as setbm, @metadata_type51 as metadata_type, @lineage_old51 as lineage_old, @p654 as c4
, @p655 as c5
, @p656 as c6
, @p657 as c7
, @p658 as c8
, @p659 as c9
, 
            @p660 as c10
, @p661 as c11
, @p662 as c12
) as rows
    inner join [dbo].[SANPHAM] t with (rowlock) on rows.rowguid = t.[rowguid]
        and rows.rowguid is not null
    left outer join dbo.MSmerge_contents cont with (rowlock) on rows.rowguid = cont.rowguid 
    and cont.tablenick = 49871000
    where  ((rows.metadata_type = 2 and cont.rowguid is not NULL and cont.lineage = rows.lineage_old) or
           (rows.metadata_type = 3 and cont.rowguid is NULL))
           and rows.rowguid is not null
    
    select @rowcount = @@rowcount, @error = @@error

    select @rows_updated = @rowcount
    if (@rows_updated <> @rows_tobe_updated) or (@error <> 0)
    begin
        raiserror(20695, 16, -1, @rows_updated, @rows_tobe_updated, 'SANPHAM')
        set @errcode= 3
        goto Failure
    end

    update dbo.MSmerge_contents with (rowlock)
    set generation = rows.generation,
        lineage = rows.lineage_new,
        colv1 = rows.colv
    from (

    select @rowguid1 as rowguid, @generation1 as generation, @lineage_new1 as lineage_new, @colv1 as colv union all
    select @rowguid2 as rowguid, @generation2 as generation, @lineage_new2 as lineage_new, @colv2 as colv union all
    select @rowguid3 as rowguid, @generation3 as generation, @lineage_new3 as lineage_new, @colv3 as colv union all
    select @rowguid4 as rowguid, @generation4 as generation, @lineage_new4 as lineage_new, @colv4 as colv union all
    select @rowguid5 as rowguid, @generation5 as generation, @lineage_new5 as lineage_new, @colv5 as colv union all
    select @rowguid6 as rowguid, @generation6 as generation, @lineage_new6 as lineage_new, @colv6 as colv union all
    select @rowguid7 as rowguid, @generation7 as generation, @lineage_new7 as lineage_new, @colv7 as colv union all
    select @rowguid8 as rowguid, @generation8 as generation, @lineage_new8 as lineage_new, @colv8 as colv union all
    select @rowguid9 as rowguid, @generation9 as generation, @lineage_new9 as lineage_new, @colv9 as colv union all
    select @rowguid10 as rowguid, @generation10 as generation, @lineage_new10 as lineage_new, @colv10 as colv union all
    select @rowguid11 as rowguid, @generation11 as generation, @lineage_new11 as lineage_new, @colv11 as colv union all
    select @rowguid12 as rowguid, @generation12 as generation, @lineage_new12 as lineage_new, @colv12 as colv union all
    select @rowguid13 as rowguid, @generation13 as generation, @lineage_new13 as lineage_new, @colv13 as colv union all
    select @rowguid14 as rowguid, @generation14 as generation, @lineage_new14 as lineage_new, @colv14 as colv union all
    select @rowguid15 as rowguid, @generation15 as generation, @lineage_new15 as lineage_new, @colv15 as colv union all
    select @rowguid16 as rowguid, @generation16 as generation, @lineage_new16 as lineage_new, @colv16 as colv union all
    select @rowguid17 as rowguid, @generation17 as generation, @lineage_new17 as lineage_new, @colv17 as colv union all
    select @rowguid18 as rowguid, @generation18 as generation, @lineage_new18 as lineage_new, @colv18 as colv union all
    select @rowguid19 as rowguid, @generation19 as generation, @lineage_new19 as lineage_new, @colv19 as colv union all
    select @rowguid20 as rowguid, @generation20 as generation, @lineage_new20 as lineage_new, @colv20 as colv union all
    select @rowguid21 as rowguid, @generation21 as generation, @lineage_new21 as lineage_new, @colv21 as colv union all
    select @rowguid22 as rowguid, @generation22 as generation, @lineage_new22 as lineage_new, @colv22 as colv union all
    select @rowguid23 as rowguid, @generation23 as generation, @lineage_new23 as lineage_new, @colv23 as colv union all
    select @rowguid24 as rowguid, @generation24 as generation, @lineage_new24 as lineage_new, @colv24 as colv union all
    select @rowguid25 as rowguid, @generation25 as generation, @lineage_new25 as lineage_new, @colv25 as colv union all
    select @rowguid26 as rowguid, @generation26 as generation, @lineage_new26 as lineage_new, @colv26 as colv union all
    select @rowguid27 as rowguid, @generation27 as generation, @lineage_new27 as lineage_new, @colv27 as colv union all
    select @rowguid28 as rowguid, @generation28 as generation, @lineage_new28 as lineage_new, @colv28 as colv union all
    select @rowguid29 as rowguid, @generation29 as generation, @lineage_new29 as lineage_new, @colv29 as colv union all
    select @rowguid30 as rowguid, @generation30 as generation, @lineage_new30 as lineage_new, @colv30 as colv union all
    select @rowguid31 as rowguid, @generation31 as generation, @lineage_new31 as lineage_new, @colv31 as colv union all
    select @rowguid32 as rowguid, @generation32 as generation, @lineage_new32 as lineage_new, @colv32 as colv
 union all
    select @rowguid33 as rowguid, @generation33 as generation, @lineage_new33 as lineage_new, @colv33 as colv union all
    select @rowguid34 as rowguid, @generation34 as generation, @lineage_new34 as lineage_new, @colv34 as colv union all
    select @rowguid35 as rowguid, @generation35 as generation, @lineage_new35 as lineage_new, @colv35 as colv union all
    select @rowguid36 as rowguid, @generation36 as generation, @lineage_new36 as lineage_new, @colv36 as colv union all
    select @rowguid37 as rowguid, @generation37 as generation, @lineage_new37 as lineage_new, @colv37 as colv union all
    select @rowguid38 as rowguid, @generation38 as generation, @lineage_new38 as lineage_new, @colv38 as colv union all
    select @rowguid39 as rowguid, @generation39 as generation, @lineage_new39 as lineage_new, @colv39 as colv union all
    select @rowguid40 as rowguid, @generation40 as generation, @lineage_new40 as lineage_new, @colv40 as colv union all
    select @rowguid41 as rowguid, @generation41 as generation, @lineage_new41 as lineage_new, @colv41 as colv union all
    select @rowguid42 as rowguid, @generation42 as generation, @lineage_new42 as lineage_new, @colv42 as colv union all
    select @rowguid43 as rowguid, @generation43 as generation, @lineage_new43 as lineage_new, @colv43 as colv union all
    select @rowguid44 as rowguid, @generation44 as generation, @lineage_new44 as lineage_new, @colv44 as colv union all
    select @rowguid45 as rowguid, @generation45 as generation, @lineage_new45 as lineage_new, @colv45 as colv union all
    select @rowguid46 as rowguid, @generation46 as generation, @lineage_new46 as lineage_new, @colv46 as colv union all
    select @rowguid47 as rowguid, @generation47 as generation, @lineage_new47 as lineage_new, @colv47 as colv union all
    select @rowguid48 as rowguid, @generation48 as generation, @lineage_new48 as lineage_new, @colv48 as colv union all
    select @rowguid49 as rowguid, @generation49 as generation, @lineage_new49 as lineage_new, @colv49 as colv union all
    select @rowguid50 as rowguid, @generation50 as generation, @lineage_new50 as lineage_new, @colv50 as colv union all
    select @rowguid51 as rowguid, @generation51 as generation, @lineage_new51 as lineage_new, @colv51 as colv

    ) as rows
    inner join dbo.MSmerge_contents cont with (rowlock) 
    on cont.rowguid = rows.rowguid and cont.tablenick = 49871000
    and rows.rowguid is not NULL 
    and rows.lineage_new is not NULL
    option (force order, loop join)
    select @cont_rows_updated = @@rowcount, @error = @@error
    if @error<>0
    begin
        set @errcode= 3
        goto Failure
    end

    if @cont_rows_updated <> @rows_tobe_updated
    begin

        insert into dbo.MSmerge_contents with (rowlock)
        (tablenick, rowguid, lineage, colv1, generation)
        select 49871000, rows.rowguid, rows.lineage_new, rows.colv, rows.generation
        from (

    select @rowguid1 as rowguid, @generation1 as generation, @lineage_new1 as lineage_new, @colv1 as colv union all
    select @rowguid2 as rowguid, @generation2 as generation, @lineage_new2 as lineage_new, @colv2 as colv union all
    select @rowguid3 as rowguid, @generation3 as generation, @lineage_new3 as lineage_new, @colv3 as colv union all
    select @rowguid4 as rowguid, @generation4 as generation, @lineage_new4 as lineage_new, @colv4 as colv union all
    select @rowguid5 as rowguid, @generation5 as generation, @lineage_new5 as lineage_new, @colv5 as colv union all
    select @rowguid6 as rowguid, @generation6 as generation, @lineage_new6 as lineage_new, @colv6 as colv union all
    select @rowguid7 as rowguid, @generation7 as generation, @lineage_new7 as lineage_new, @colv7 as colv union all
    select @rowguid8 as rowguid, @generation8 as generation, @lineage_new8 as lineage_new, @colv8 as colv union all
    select @rowguid9 as rowguid, @generation9 as generation, @lineage_new9 as lineage_new, @colv9 as colv union all
    select @rowguid10 as rowguid, @generation10 as generation, @lineage_new10 as lineage_new, @colv10 as colv union all
    select @rowguid11 as rowguid, @generation11 as generation, @lineage_new11 as lineage_new, @colv11 as colv union all
    select @rowguid12 as rowguid, @generation12 as generation, @lineage_new12 as lineage_new, @colv12 as colv union all
    select @rowguid13 as rowguid, @generation13 as generation, @lineage_new13 as lineage_new, @colv13 as colv union all
    select @rowguid14 as rowguid, @generation14 as generation, @lineage_new14 as lineage_new, @colv14 as colv union all
    select @rowguid15 as rowguid, @generation15 as generation, @lineage_new15 as lineage_new, @colv15 as colv union all
    select @rowguid16 as rowguid, @generation16 as generation, @lineage_new16 as lineage_new, @colv16 as colv union all
    select @rowguid17 as rowguid, @generation17 as generation, @lineage_new17 as lineage_new, @colv17 as colv union all
    select @rowguid18 as rowguid, @generation18 as generation, @lineage_new18 as lineage_new, @colv18 as colv union all
    select @rowguid19 as rowguid, @generation19 as generation, @lineage_new19 as lineage_new, @colv19 as colv union all
    select @rowguid20 as rowguid, @generation20 as generation, @lineage_new20 as lineage_new, @colv20 as colv union all
    select @rowguid21 as rowguid, @generation21 as generation, @lineage_new21 as lineage_new, @colv21 as colv union all
    select @rowguid22 as rowguid, @generation22 as generation, @lineage_new22 as lineage_new, @colv22 as colv union all
    select @rowguid23 as rowguid, @generation23 as generation, @lineage_new23 as lineage_new, @colv23 as colv union all
    select @rowguid24 as rowguid, @generation24 as generation, @lineage_new24 as lineage_new, @colv24 as colv union all
    select @rowguid25 as rowguid, @generation25 as generation, @lineage_new25 as lineage_new, @colv25 as colv union all
    select @rowguid26 as rowguid, @generation26 as generation, @lineage_new26 as lineage_new, @colv26 as colv union all
    select @rowguid27 as rowguid, @generation27 as generation, @lineage_new27 as lineage_new, @colv27 as colv union all
    select @rowguid28 as rowguid, @generation28 as generation, @lineage_new28 as lineage_new, @colv28 as colv union all
    select @rowguid29 as rowguid, @generation29 as generation, @lineage_new29 as lineage_new, @colv29 as colv union all
    select @rowguid30 as rowguid, @generation30 as generation, @lineage_new30 as lineage_new, @colv30 as colv union all
    select @rowguid31 as rowguid, @generation31 as generation, @lineage_new31 as lineage_new, @colv31 as colv union all
    select @rowguid32 as rowguid, @generation32 as generation, @lineage_new32 as lineage_new, @colv32 as colv
 union all
    select @rowguid33 as rowguid, @generation33 as generation, @lineage_new33 as lineage_new, @colv33 as colv union all
    select @rowguid34 as rowguid, @generation34 as generation, @lineage_new34 as lineage_new, @colv34 as colv union all
    select @rowguid35 as rowguid, @generation35 as generation, @lineage_new35 as lineage_new, @colv35 as colv union all
    select @rowguid36 as rowguid, @generation36 as generation, @lineage_new36 as lineage_new, @colv36 as colv union all
    select @rowguid37 as rowguid, @generation37 as generation, @lineage_new37 as lineage_new, @colv37 as colv union all
    select @rowguid38 as rowguid, @generation38 as generation, @lineage_new38 as lineage_new, @colv38 as colv union all
    select @rowguid39 as rowguid, @generation39 as generation, @lineage_new39 as lineage_new, @colv39 as colv union all
    select @rowguid40 as rowguid, @generation40 as generation, @lineage_new40 as lineage_new, @colv40 as colv union all
    select @rowguid41 as rowguid, @generation41 as generation, @lineage_new41 as lineage_new, @colv41 as colv union all
    select @rowguid42 as rowguid, @generation42 as generation, @lineage_new42 as lineage_new, @colv42 as colv union all
    select @rowguid43 as rowguid, @generation43 as generation, @lineage_new43 as lineage_new, @colv43 as colv union all
    select @rowguid44 as rowguid, @generation44 as generation, @lineage_new44 as lineage_new, @colv44 as colv union all
    select @rowguid45 as rowguid, @generation45 as generation, @lineage_new45 as lineage_new, @colv45 as colv union all
    select @rowguid46 as rowguid, @generation46 as generation, @lineage_new46 as lineage_new, @colv46 as colv union all
    select @rowguid47 as rowguid, @generation47 as generation, @lineage_new47 as lineage_new, @colv47 as colv union all
    select @rowguid48 as rowguid, @generation48 as generation, @lineage_new48 as lineage_new, @colv48 as colv union all
    select @rowguid49 as rowguid, @generation49 as generation, @lineage_new49 as lineage_new, @colv49 as colv union all
    select @rowguid50 as rowguid, @generation50 as generation, @lineage_new50 as lineage_new, @colv50 as colv union all
    select @rowguid51 as rowguid, @generation51 as generation, @lineage_new51 as lineage_new, @colv51 as colv

        ) as rows
        left outer join dbo.MSmerge_contents cont with (rowlock) 
        on cont.rowguid = rows.rowguid and cont.tablenick = 49871000
        and rows.rowguid is not NULL
        and rows.lineage_new is not NULL
        where cont.rowguid is NULL
        and rows.rowguid is not NULL
        and rows.lineage_new is not NULL
        
        if @@error<>0
        begin
            set @errcode= 3
            goto Failure
        end
    end

    exec @retcode = sys.sp_MSdeletemetadataactionrequest '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800', 49871000, 
        @rowguid1, 
        @rowguid2, 
        @rowguid3, 
        @rowguid4, 
        @rowguid5, 
        @rowguid6, 
        @rowguid7, 
        @rowguid8, 
        @rowguid9, 
        @rowguid10, 
        @rowguid11, 
        @rowguid12, 
        @rowguid13, 
        @rowguid14, 
        @rowguid15, 
        @rowguid16, 
        @rowguid17, 
        @rowguid18, 
        @rowguid19, 
        @rowguid20, 
        @rowguid21, 
        @rowguid22, 
        @rowguid23, 
        @rowguid24, 
        @rowguid25, 
        @rowguid26, 
        @rowguid27, 
        @rowguid28, 
        @rowguid29, 
        @rowguid30, 
        @rowguid31, 
        @rowguid32, 
        @rowguid33, 
        @rowguid34, 
        @rowguid35, 
        @rowguid36, 
        @rowguid37, 
        @rowguid38, 
        @rowguid39, 
        @rowguid40, 
        @rowguid41, 
        @rowguid42, 
        @rowguid43, 
        @rowguid44, 
        @rowguid45, 
        @rowguid46, 
        @rowguid47, 
        @rowguid48, 
        @rowguid49, 
        @rowguid50, 
        @rowguid51
    if @retcode<>0 or @@error<>0
        goto Failure
    

    commit tran
    return 1

Failure:
    rollback tran batchupdateproc
    commit tran
    return 0
end


go

update dbo.sysmergepartitioninfo 
    set column_list = N't.[MASP], t.[MANCC], t.[MALOAI], t.[TENSP], t.[DONGIA], t.[DVT], t.[SOLUONG], t.[ANH], t.[MOTA], t.[KICHTHUOC], t.[TRONGLUONG], t.[MAUSAC], t.[rowguid]', 
        column_list_blob = N't.[MASP], t.[MANCC], t.[MALOAI], t.[TENSP], t.[DONGIA], t.[DVT], t.[SOLUONG], t.[ANH], t.[KICHTHUOC], t.[TRONGLUONG], t.[MAUSAC], t.[rowguid], t.[MOTA]'
    where artid = 'D6E4E45B-6464-42AC-B69C-D1829FE51344' and pubid = '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'

go
SET ANSI_NULLS ON SET QUOTED_IDENTIFIER ON

go

    create procedure dbo.[MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B] (
        @maxschemaguidforarticle uniqueidentifier,
        @type int output, 
        @rowguid uniqueidentifier=NULL,
        @enumentirerowmetadata bit= 1,
        @blob_cols_at_the_end bit=0,
        @logical_record_parent_rowguid uniqueidentifier = '00000000-0000-0000-0000-000000000000',
        @metadata_type tinyint = 0,
        @lineage_old varbinary(311) = NULL,
        @rowcount int = NULL output
        ) 
    as
    begin
        declare @retcode    int
        
        set nocount on
            
        if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
        begin       
            RAISERROR (14126, 11, -1)
            return (1)
        end 

    if @type = 1
        begin
            select 
t.[MASP]
,
        t.[MANCC]
,
        t.[MALOAI]
,
        t.[TENSP]
,
        t.[DONGIA]
,
        t.[DVT]
,
        t.[SOLUONG]
,
        t.[ANH]
,
        t.[MOTA]
,
        t.[KICHTHUOC]
,
        t.[TRONGLUONG]
,
        t.[MAUSAC]
,
        t.rowguidcol
          from [dbo].[SANPHAM] t where rowguidcol = @rowguid
        if @@ERROR<>0 return(1)
    end 
    else if @type < 4 
        begin
            -- case one: no blob gen optimization
            if @blob_cols_at_the_end=0
            begin
                select 
                c.tablenick, 
                c.rowguid, 
                c.generation,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.lineage
                end as lineage,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.colv1
                end as colv1,
                
t.[MASP]
,
        t.[MANCC]
,
        t.[MALOAI]
,
        t.[TENSP]
,
        t.[DONGIA]
,
        t.[DVT]
,
        t.[SOLUONG]
,
        t.[ANH]
,
        t.[MOTA]
,
        t.[KICHTHUOC]
,
        t.[TRONGLUONG]
,
        t.[MAUSAC]
,
        t.rowguidcol

                from #cont c , [dbo].[SANPHAM] t with (rowlock)
                where t.rowguidcol = c.rowguid
                order by t.rowguidcol 
                
            if @@ERROR<>0 return(1)
            end
  
            -- case two: blob gen optimization
            else 
            begin
                select 
                c.tablenick, 
                c.rowguid, 
                c.generation,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.lineage
                end as lineage,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.colv1
                end as colv1,
t.[MASP]
 ,
        t.[MANCC]
 ,
        t.[MALOAI]
 ,
        t.[TENSP]
 ,
        t.[DONGIA]
 ,
        t.[DVT]
 ,
        t.[SOLUONG]
 ,
        t.[ANH]
 ,
        t.[KICHTHUOC]
 ,
        t.[TRONGLUONG]
 ,
        t.[MAUSAC]
 ,
        t.rowguidcol
 ,
        t.[MOTA]

                from #cont c,[dbo].[SANPHAM] t with (rowlock)
              where t.rowguidcol = c.rowguid
                 order by t.rowguidcol 
                 
            if @@ERROR<>0 return(1)
            end
        end
   else if @type = 4
    begin
        set @type = 0
        if exists (select * from [dbo].[SANPHAM] where rowguidcol = @rowguid)
            set @type = 3
        if @@ERROR<>0 return(1)
    end

    else if @type = 5
    begin
         
        delete [dbo].[SANPHAM] where rowguidcol = @rowguid
        if @@ERROR<>0 return(1)

        delete from dbo.MSmerge_metadataaction_request
            where tablenick=49871000 and rowguid=@rowguid
    end 

    else if @type = 6 -- sp_MSenumcolumns
    begin
        select 
t.[MASP]
,
        t.[MANCC]
,
        t.[MALOAI]
,
        t.[TENSP]
,
        t.[DONGIA]
,
        t.[DVT]
,
        t.[SOLUONG]
,
        t.[ANH]
,
        t.[MOTA]
,
        t.[KICHTHUOC]
,
        t.[TRONGLUONG]
,
        t.[MAUSAC]
,
        t.rowguidcol
         from [dbo].[SANPHAM] t where 1=2
        if @@ERROR<>0 return(1)
    end

    else if @type = 7 -- sp_MSlocktable
    begin
        select 1 from [dbo].[SANPHAM] with (tablock holdlock) where 1 = 2
        if @@ERROR<>0 return(1)
    end

    else if @type = 8 -- put update lock
    begin
        if not exists (select * from [dbo].[SANPHAM] with (UPDLOCK HOLDLOCK) where rowguidcol = @rowguid)
        begin
            RAISERROR(20031 , 16, -1)
            return(1)
        end
    end
    else if @type = 9
    begin
        declare @oldmaxversion int, @replnick binary(6)
                , @cur_article_rowcount int, @column_tracking int
                        
        select @replnick = 0x557903146b6f

        select top 1 @oldmaxversion = maxversion_at_cleanup,
                     @column_tracking = column_tracking
        from dbo.sysmergearticles 
        where nickname = 49871000
        
        select @cur_article_rowcount = count(*) from #rows 
        where tablenick = 49871000
            
        update dbo.MSmerge_contents 
        set lineage = { fn UPDATELINEAGE(lineage, @replnick, @oldmaxversion+1) }
        where tablenick = 49871000
        and rowguid in (select rowguid from #rows where tablenick = 49871000) 

        if @@rowcount <> @cur_article_rowcount
        begin
            declare @lineage varbinary(311), @colv1 varbinary(1)
                    , @cur_rowguid uniqueidentifier, @prev_rowguid uniqueidentifier
            set @lineage = { fn UPDATELINEAGE(0x0, @replnick, @oldmaxversion+1) }
            if @column_tracking <> 0
                set @colv1 = 0xFF
            else
                set @colv1 = NULL
                
            select top 1 @cur_rowguid = rowguid from #rows
            where tablenick = 49871000
            order by rowguid
            
            while @cur_rowguid is not null
            begin
                if not exists (select * from dbo.MSmerge_contents 
                                where tablenick = 49871000
                                and rowguid = @cur_rowguid)
                begin
                    begin tran 
                    save tran insert_contents_row 

                    if exists (select * from [dbo].[SANPHAM]with (holdlock) where rowguidcol = @cur_rowguid)
                    begin
                        exec @retcode = sys.sp_MSevaluate_change_membership_for_row @tablenick = 49871000, @rowguid = @cur_rowguid
                        if @retcode <> 0 or @@error <> 0
                        begin
                            rollback tran insert_contents_row
                            return 1
                        end
                        insert into dbo.MSmerge_contents (rowguid, tablenick, generation, lineage, colv1, logical_record_parent_rowguid)
                            values (@cur_rowguid, 49871000, 0, @lineage, @colv1, @logical_record_parent_rowguid)
                    end
                    commit tran
                end
                
                select @prev_rowguid = @cur_rowguid
                select @cur_rowguid = NULL
                
                select top 1 @cur_rowguid = rowguid from #rows
                where tablenick = 49871000
                and rowguid > @prev_rowguid
                order by rowguid
            end
        end 

        select 
            r.tablenick, 
            r.rowguid, 
            mc.generation,
            case @enumentirerowmetadata
                when 0 then null
                else mc.lineage
            end,
            case @enumentirerowmetadata
                when 0 then null
                else mc.colv1
            end,
            
t.[MASP]
,
        t.[MANCC]
,
        t.[MALOAI]
,
        t.[TENSP]
,
        t.[DONGIA]
,
        t.[DVT]
,
        t.[SOLUONG]
,
        t.[ANH]
,
        t.[MOTA]
,
        t.[KICHTHUOC]
,
        t.[TRONGLUONG]
,
        t.[MAUSAC]
,
        t.rowguidcol
         from #rows r left outer join [dbo].[SANPHAM] t on r.rowguid = t.rowguidcol and r.tablenick = 49871000
                 left outer join dbo.MSmerge_contents mc on
                 mc.tablenick = 49871000 and mc.rowguid = t.rowguidcol
                 where r.tablenick = 49871000
         order by r.idx
         
        if @@ERROR<>0 return(1)
    end 

        else if @type = 10  
        begin
            select 
                c.tablenick, 
                c.rowguid, 
                c.generation,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.lineage
                end,
                case @enumentirerowmetadata
                    when 0 then null
                    else c.colv1
                end,
                null,
                
t.[MASP]
,
        t.[MANCC]
,
        t.[MALOAI]
,
        t.[TENSP]
,
        t.[DONGIA]
,
        t.[DVT]
,
        t.[SOLUONG]
,
        t.[ANH]
,
        t.[MOTA]
,
        t.[KICHTHUOC]
,
        t.[TRONGLUONG]
,
        t.[MAUSAC]
,
        t.rowguidcol
         from #cont c,[dbo].[SANPHAM] t with (rowlock) where
                      t.rowguidcol = c.rowguid
             order by t.rowguidcol 
                        
            if @@ERROR<>0 return(1)
        end

    else if @type = 11
    begin
         
        -- we will do a delete with metadata match
        if @metadata_type = 0
        begin
            delete from [dbo].[SANPHAM] where [rowguid] = @rowguid
            select @rowcount = @@rowcount
            if @rowcount <> 1
            begin
                RAISERROR(20031 , 16, -1)
                return(1)
            end
        end
        else
        begin
            if @metadata_type = 3
                delete [dbo].[SANPHAM] from [dbo].[SANPHAM] t
                    where t.[rowguid] = @rowguid and 
                        not exists (select 1 from dbo.MSmerge_contents c with (rowlock) where
                                                c.rowguid = @rowguid and
                                                c.tablenick = 49871000)
            else if @metadata_type = 5 or @metadata_type = 6
                delete [dbo].[SANPHAM] from [dbo].[SANPHAM] t
                    where t.[rowguid] = @rowguid and 
                         not exists (select 1 from dbo.MSmerge_contents c with (rowlock) where
                                                c.rowguid = @rowguid and
                                                c.tablenick = 49871000 and
                                                c.lineage <> @lineage_old)
                                                
            else
                delete [dbo].[SANPHAM] from [dbo].[SANPHAM] t
                    where t.[rowguid] = @rowguid and 
                         exists (select 1 from dbo.MSmerge_contents c with (rowlock) where
                                                c.rowguid = @rowguid and
                                                c.tablenick = 49871000 and
                                                c.lineage = @lineage_old)
            select @rowcount = @@rowcount
            if @rowcount <> 1 
            begin
                if not exists (select * from [dbo].[SANPHAM] where [rowguid] = @rowguid)
                begin
                    RAISERROR(20031 , 16, -1)
                    return(1)
                end
            end
        end
        if @@ERROR<>0 
        begin
            delete from dbo.MSmerge_metadataaction_request
                where tablenick=49871000 and rowguid=@rowguid

            return(1)
        end        
    end

    else if @type = 12
    begin 
        -- this type indicates metadata type selection
        declare @maxversion int
        declare @error int
        
        select @maxversion= maxversion_at_cleanup from dbo.sysmergearticles 
            where nickname = 49871000 and pubid = '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'
        if @error <> 0 
            return 1
        select case when (cont.generation is NULL and tomb.generation is null) 
                    then 0 
                    else isnull(cont.generation, tomb.generation) 
               end as generation, 
               case when t.[rowguid] is null 
                    then (case when tomb.rowguid is NULL then 0 else tomb.type end) 
                    else (case when cont.rowguid is null then 3 else 2 end) 
               end as type,
               case when tomb.rowguid is null 
                    then cont.lineage 
                    else tomb.lineage
               end as lineage, 
               cont.colv1 as colv, 
               @maxversion as maxversion
        from
        (select @rowguid as rowguid) as rows 
        left outer join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid
        and rows.rowguid is not null
        left outer join dbo.MSmerge_contents cont with (rowlock) 
        on cont.rowguid = rows.rowguid and cont.tablenick = 49871000
        left outer join dbo.MSmerge_tombstone tomb with (rowlock) 
        on tomb.rowguid = rows.rowguid and tomb.tablenick = 49871000
        where rows.rowguid is not null
        
        select @error = @@error
        if @error <> 0 
        begin
            --raiserror(@error, 16, -1)
            return 1
        end
    end

    return(0)
end


go

create procedure dbo.[MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B_metadata]
( 
    @rowguid1 uniqueidentifier,
    @rowguid2 uniqueidentifier = NULL,
    @rowguid3 uniqueidentifier = NULL,
    @rowguid4 uniqueidentifier = NULL,
    @rowguid5 uniqueidentifier = NULL,
    @rowguid6 uniqueidentifier = NULL,
    @rowguid7 uniqueidentifier = NULL,
    @rowguid8 uniqueidentifier = NULL,
    @rowguid9 uniqueidentifier = NULL,
    @rowguid10 uniqueidentifier = NULL,
    @rowguid11 uniqueidentifier = NULL,
    @rowguid12 uniqueidentifier = NULL,
    @rowguid13 uniqueidentifier = NULL,
    @rowguid14 uniqueidentifier = NULL,
    @rowguid15 uniqueidentifier = NULL,
    @rowguid16 uniqueidentifier = NULL,
    @rowguid17 uniqueidentifier = NULL,
    @rowguid18 uniqueidentifier = NULL,
    @rowguid19 uniqueidentifier = NULL,
    @rowguid20 uniqueidentifier = NULL,
    @rowguid21 uniqueidentifier = NULL,
    @rowguid22 uniqueidentifier = NULL,
    @rowguid23 uniqueidentifier = NULL,
    @rowguid24 uniqueidentifier = NULL,
    @rowguid25 uniqueidentifier = NULL,
    @rowguid26 uniqueidentifier = NULL,
    @rowguid27 uniqueidentifier = NULL,
    @rowguid28 uniqueidentifier = NULL,
    @rowguid29 uniqueidentifier = NULL,
    @rowguid30 uniqueidentifier = NULL,
    @rowguid31 uniqueidentifier = NULL,
    @rowguid32 uniqueidentifier = NULL,
    @rowguid33 uniqueidentifier = NULL,
    @rowguid34 uniqueidentifier = NULL,
    @rowguid35 uniqueidentifier = NULL,
    @rowguid36 uniqueidentifier = NULL,
    @rowguid37 uniqueidentifier = NULL,
    @rowguid38 uniqueidentifier = NULL,
    @rowguid39 uniqueidentifier = NULL,
    @rowguid40 uniqueidentifier = NULL,
    @rowguid41 uniqueidentifier = NULL,
    @rowguid42 uniqueidentifier = NULL,
    @rowguid43 uniqueidentifier = NULL,
    @rowguid44 uniqueidentifier = NULL,
    @rowguid45 uniqueidentifier = NULL,
    @rowguid46 uniqueidentifier = NULL,
    @rowguid47 uniqueidentifier = NULL,
    @rowguid48 uniqueidentifier = NULL,
    @rowguid49 uniqueidentifier = NULL,
    @rowguid50 uniqueidentifier = NULL,

    @rowguid51 uniqueidentifier = NULL,
    @rowguid52 uniqueidentifier = NULL,
    @rowguid53 uniqueidentifier = NULL,
    @rowguid54 uniqueidentifier = NULL,
    @rowguid55 uniqueidentifier = NULL,
    @rowguid56 uniqueidentifier = NULL,
    @rowguid57 uniqueidentifier = NULL,
    @rowguid58 uniqueidentifier = NULL,
    @rowguid59 uniqueidentifier = NULL,
    @rowguid60 uniqueidentifier = NULL,
    @rowguid61 uniqueidentifier = NULL,
    @rowguid62 uniqueidentifier = NULL,
    @rowguid63 uniqueidentifier = NULL,
    @rowguid64 uniqueidentifier = NULL,
    @rowguid65 uniqueidentifier = NULL,
    @rowguid66 uniqueidentifier = NULL,
    @rowguid67 uniqueidentifier = NULL,
    @rowguid68 uniqueidentifier = NULL,
    @rowguid69 uniqueidentifier = NULL,
    @rowguid70 uniqueidentifier = NULL,
    @rowguid71 uniqueidentifier = NULL,
    @rowguid72 uniqueidentifier = NULL,
    @rowguid73 uniqueidentifier = NULL,
    @rowguid74 uniqueidentifier = NULL,
    @rowguid75 uniqueidentifier = NULL,
    @rowguid76 uniqueidentifier = NULL,
    @rowguid77 uniqueidentifier = NULL,
    @rowguid78 uniqueidentifier = NULL,
    @rowguid79 uniqueidentifier = NULL,
    @rowguid80 uniqueidentifier = NULL,
    @rowguid81 uniqueidentifier = NULL,
    @rowguid82 uniqueidentifier = NULL,
    @rowguid83 uniqueidentifier = NULL,
    @rowguid84 uniqueidentifier = NULL,
    @rowguid85 uniqueidentifier = NULL,
    @rowguid86 uniqueidentifier = NULL,
    @rowguid87 uniqueidentifier = NULL,
    @rowguid88 uniqueidentifier = NULL,
    @rowguid89 uniqueidentifier = NULL,
    @rowguid90 uniqueidentifier = NULL,
    @rowguid91 uniqueidentifier = NULL,
    @rowguid92 uniqueidentifier = NULL,
    @rowguid93 uniqueidentifier = NULL,
    @rowguid94 uniqueidentifier = NULL,
    @rowguid95 uniqueidentifier = NULL,
    @rowguid96 uniqueidentifier = NULL,
    @rowguid97 uniqueidentifier = NULL,
    @rowguid98 uniqueidentifier = NULL,
    @rowguid99 uniqueidentifier = NULL,
    @rowguid100 uniqueidentifier = NULL
) 

as
begin
    declare @retcode    int
    declare @maxversion int
    set nocount on
        
    if ({ fn ISPALUSER('5FF3F1A6-6586-4D7B-ACF5-B25994FEB800') } <> 1)
    begin       
        RAISERROR (14126, 11, -1)
        return (1)
    end
    
    select @maxversion= maxversion_at_cleanup from dbo.sysmergearticles 
        where nickname = 49871000 and pubid = '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'


        select case when (cont.generation is NULL and tomb.generation is null) then 0 else isnull(cont.generation, tomb.generation) end as generation, 
               case when t.[rowguid] is null then (case when tomb.rowguid is NULL then 0 else tomb.type end) else (case when cont.rowguid is null then 3 else 2 end) end as type,
               case when tomb.rowguid is null then cont.lineage else tomb.lineage end as lineage,  
               cont.colv1 as colv,
               @maxversion as maxversion,
               rows.rowguid as rowguid
    

        from
        ( 
        select @rowguid1 as rowguid, 1 as sortcol union all
        select @rowguid2 as rowguid, 2 as sortcol union all
        select @rowguid3 as rowguid, 3 as sortcol union all
        select @rowguid4 as rowguid, 4 as sortcol union all
        select @rowguid5 as rowguid, 5 as sortcol union all
        select @rowguid6 as rowguid, 6 as sortcol union all
        select @rowguid7 as rowguid, 7 as sortcol union all
        select @rowguid8 as rowguid, 8 as sortcol union all
        select @rowguid9 as rowguid, 9 as sortcol union all
        select @rowguid10 as rowguid, 10 as sortcol union all
        select @rowguid11 as rowguid, 11 as sortcol union all
        select @rowguid12 as rowguid, 12 as sortcol union all
        select @rowguid13 as rowguid, 13 as sortcol union all
        select @rowguid14 as rowguid, 14 as sortcol union all
        select @rowguid15 as rowguid, 15 as sortcol union all
        select @rowguid16 as rowguid, 16 as sortcol union all
        select @rowguid17 as rowguid, 17 as sortcol union all
        select @rowguid18 as rowguid, 18 as sortcol union all
        select @rowguid19 as rowguid, 19 as sortcol union all
        select @rowguid20 as rowguid, 20 as sortcol union all
        select @rowguid21 as rowguid, 21 as sortcol union all
        select @rowguid22 as rowguid, 22 as sortcol union all
        select @rowguid23 as rowguid, 23 as sortcol union all
        select @rowguid24 as rowguid, 24 as sortcol union all
        select @rowguid25 as rowguid, 25 as sortcol union all
        select @rowguid26 as rowguid, 26 as sortcol union all
        select @rowguid27 as rowguid, 27 as sortcol union all
        select @rowguid28 as rowguid, 28 as sortcol union all
        select @rowguid29 as rowguid, 29 as sortcol union all
        select @rowguid30 as rowguid, 30 as sortcol union all
        select @rowguid31 as rowguid, 31 as sortcol union all

        select @rowguid32 as rowguid, 32 as sortcol union all
        select @rowguid33 as rowguid, 33 as sortcol union all
        select @rowguid34 as rowguid, 34 as sortcol union all
        select @rowguid35 as rowguid, 35 as sortcol union all
        select @rowguid36 as rowguid, 36 as sortcol union all
        select @rowguid37 as rowguid, 37 as sortcol union all
        select @rowguid38 as rowguid, 38 as sortcol union all
        select @rowguid39 as rowguid, 39 as sortcol union all
        select @rowguid40 as rowguid, 40 as sortcol union all
        select @rowguid41 as rowguid, 41 as sortcol union all
        select @rowguid42 as rowguid, 42 as sortcol union all
        select @rowguid43 as rowguid, 43 as sortcol union all
        select @rowguid44 as rowguid, 44 as sortcol union all
        select @rowguid45 as rowguid, 45 as sortcol union all
        select @rowguid46 as rowguid, 46 as sortcol union all
        select @rowguid47 as rowguid, 47 as sortcol union all
        select @rowguid48 as rowguid, 48 as sortcol union all
        select @rowguid49 as rowguid, 49 as sortcol union all
        select @rowguid50 as rowguid, 50 as sortcol union all
        select @rowguid51 as rowguid, 51 as sortcol union all
        select @rowguid52 as rowguid, 52 as sortcol union all
        select @rowguid53 as rowguid, 53 as sortcol union all
        select @rowguid54 as rowguid, 54 as sortcol union all
        select @rowguid55 as rowguid, 55 as sortcol union all
        select @rowguid56 as rowguid, 56 as sortcol union all
        select @rowguid57 as rowguid, 57 as sortcol union all
        select @rowguid58 as rowguid, 58 as sortcol union all
        select @rowguid59 as rowguid, 59 as sortcol union all
        select @rowguid60 as rowguid, 60 as sortcol union all
        select @rowguid61 as rowguid, 61 as sortcol union all
        select @rowguid62 as rowguid, 62 as sortcol union all
 
        select @rowguid63 as rowguid, 63 as sortcol union all
        select @rowguid64 as rowguid, 64 as sortcol union all
        select @rowguid65 as rowguid, 65 as sortcol union all
        select @rowguid66 as rowguid, 66 as sortcol union all
        select @rowguid67 as rowguid, 67 as sortcol union all
        select @rowguid68 as rowguid, 68 as sortcol union all
        select @rowguid69 as rowguid, 69 as sortcol union all
        select @rowguid70 as rowguid, 70 as sortcol union all
        select @rowguid71 as rowguid, 71 as sortcol union all
        select @rowguid72 as rowguid, 72 as sortcol union all
        select @rowguid73 as rowguid, 73 as sortcol union all
        select @rowguid74 as rowguid, 74 as sortcol union all
        select @rowguid75 as rowguid, 75 as sortcol union all
        select @rowguid76 as rowguid, 76 as sortcol union all
        select @rowguid77 as rowguid, 77 as sortcol union all
        select @rowguid78 as rowguid, 78 as sortcol union all
        select @rowguid79 as rowguid, 79 as sortcol union all
        select @rowguid80 as rowguid, 80 as sortcol union all
        select @rowguid81 as rowguid, 81 as sortcol union all
        select @rowguid82 as rowguid, 82 as sortcol union all
        select @rowguid83 as rowguid, 83 as sortcol union all
        select @rowguid84 as rowguid, 84 as sortcol union all
        select @rowguid85 as rowguid, 85 as sortcol union all
        select @rowguid86 as rowguid, 86 as sortcol union all
        select @rowguid87 as rowguid, 87 as sortcol union all
        select @rowguid88 as rowguid, 88 as sortcol union all
        select @rowguid89 as rowguid, 89 as sortcol union all
        select @rowguid90 as rowguid, 90 as sortcol union all
        select @rowguid91 as rowguid, 91 as sortcol union all
        select @rowguid92 as rowguid, 92 as sortcol union all
        select @rowguid93 as rowguid, 93 as sortcol union all
 
        select @rowguid94 as rowguid, 94 as sortcol union all
        select @rowguid95 as rowguid, 95 as sortcol union all
        select @rowguid96 as rowguid, 96 as sortcol union all
        select @rowguid97 as rowguid, 97 as sortcol union all
        select @rowguid98 as rowguid, 98 as sortcol union all
        select @rowguid99 as rowguid, 99 as sortcol union all
        select @rowguid100 as rowguid, 100 as sortcol
        ) as rows 

        left outer join [dbo].[SANPHAM] t with (rowlock) 
        on t.[rowguid] = rows.rowguid
        and rows.rowguid is not null
        left outer join dbo.MSmerge_contents cont with (rowlock) 
        on cont.rowguid = rows.rowguid and cont.tablenick = 49871000
        left outer join dbo.MSmerge_tombstone tomb with (rowlock) 
        on tomb.rowguid = rows.rowguid and tomb.tablenick = 49871000
        where rows.rowguid is not null
        order by rows.sortcol
                
        if @@error <> 0 
            return 1
    end
    

go
Create procedure dbo.[MSmerge_cft_sp_D6E4E45B646442AC5FF3F1A665864D7B] ( 
@p1 varchar(10), 
        @p2 varchar(10), 
        @p3 varchar(10), 
        @p4 nvarchar(50), 
        @p5 int, 
        @p6 nvarchar(50), 
        @p7 int, 
        @p8 varchar(50), 
        @p9 nvarchar(max), 
        @p10 nvarchar(50), 
        @p11 nvarchar(50), 
        @p12 nvarchar(50), 
        @p13 uniqueidentifier, 
        @p14  nvarchar(255) 
, @conflict_type int,  @reason_code int,  @reason_text nvarchar(720)
, @pubid uniqueidentifier, @create_time datetime = NULL
, @tablenick int = 0, @source_id uniqueidentifier = NULL, @check_conflicttable_existence bit = 0 
) as
declare @retcode int
-- security check
exec @retcode = sys.sp_MSrepl_PAL_rolecheck @objid = 854294103, @pubid = '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'
if @@error <> 0 or @retcode <> 0 return 1 

if 1 = @check_conflicttable_existence
begin
    if 854294103 is null return 0
end


    if @source_id is NULL 
        select @source_id = subid from dbo.sysmergesubscriptions 
            where lower(@p14) = LOWER(subscriber_server) + '.' + LOWER(db_name) 

    if @source_id is NULL select @source_id = newid() 
  
    set @create_time=getdate()

  if exists (select * from MSmerge_conflicts_info info inner join [dbo].[MSmerge_conflict_MIENNAM_SANPHAM] ct 
    on ct.rowguidcol=info.rowguid and 
       ct.origin_datasource_id = info.origin_datasource_id
     where info.rowguid = @p13 and info.origin_datasource = @p14 and info.tablenick = @tablenick)
    begin
        update [dbo].[MSmerge_conflict_MIENNAM_SANPHAM] with (rowlock) set 
[MASP] = @p1
,
        [MANCC] = @p2
,
        [MALOAI] = @p3
,
        [TENSP] = @p4
,
        [DONGIA] = @p5
,
        [DVT] = @p6
,
        [SOLUONG] = @p7
,
        [ANH] = @p8
,
        [MOTA] = @p9
,
        [KICHTHUOC] = @p10
,
        [TRONGLUONG] = @p11
,
        [MAUSAC] = @p12
 from [dbo].[MSmerge_conflict_MIENNAM_SANPHAM] ct inner join MSmerge_conflicts_info info 
        on ct.rowguidcol=info.rowguid and 
           ct.origin_datasource_id = info.origin_datasource_id
 where info.rowguid = @p13 and info.origin_datasource = @p14 and info.tablenick = @tablenick


    end
    else
    begin
        insert into [dbo].[MSmerge_conflict_MIENNAM_SANPHAM] (
[MASP]
,
        [MANCC]
,
        [MALOAI]
,
        [TENSP]
,
        [DONGIA]
,
        [DVT]
,
        [SOLUONG]
,
        [ANH]
,
        [MOTA]
,
        [KICHTHUOC]
,
        [TRONGLUONG]
,
        [MAUSAC]
,
        [rowguid]
,
        [origin_datasource_id]
) values (

@p1
,
        @p2
,
        @p3
,
        @p4
,
        @p5
,
        @p6
,
        @p7
,
        @p8
,
        @p9
,
        @p10
,
        @p11
,
        @p12
,
        @p13
,
         @source_id 
)

    end

    
    if exists (select * from MSmerge_conflicts_info info where tablenick=@tablenick and rowguid=@p13 and info.origin_datasource= @p14 and info.conflict_type not in (4,7,8,12))
    begin
        update MSmerge_conflicts_info with (rowlock) 
            set conflict_type=@conflict_type, 
                reason_code=@reason_code,
                reason_text=@reason_text,
                pubid=@pubid,
                MSrepl_create_time=@create_time
            where tablenick=@tablenick and rowguid=@p13 and origin_datasource= @p14
            and conflict_type not in (4,7,8,12)
    end
    else    
    begin
    
        insert MSmerge_conflicts_info with (rowlock) 
            values(@tablenick, @p13, @p14, @conflict_type, @reason_code, @reason_text,  @pubid, @create_time, @source_id)
    end

        declare @error    int
        set @error= @reason_code

    declare @REPOLEExtErrorDupKey            int
    declare @REPOLEExtErrorDupUniqueIndex    int

    set @REPOLEExtErrorDupKey= 2627
    set @REPOLEExtErrorDupUniqueIndex= 2601
    
    if @error in (@REPOLEExtErrorDupUniqueIndex, @REPOLEExtErrorDupKey)
    begin
        update mc
            set mc.generation= 0
            from dbo.MSmerge_contents mc join [dbo].[SANPHAM] t on mc.rowguid=t.rowguidcol
            where
                mc.tablenick = 49871000 and
                (

                        (t.[MASP]=@p1)

                        )
            end

go

update dbo.sysmergearticles 
    set insert_proc = 'MSmerge_ins_sp_D6E4E45B646442AC5FF3F1A665864D7B',
        select_proc = 'MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B',
        metadata_select_proc = 'MSmerge_sel_sp_D6E4E45B646442AC5FF3F1A665864D7B_metadata',
        update_proc = 'MSmerge_upd_sp_D6E4E45B646442AC5FF3F1A665864D7B',
        ins_conflict_proc = 'MSmerge_cft_sp_D6E4E45B646442AC5FF3F1A665864D7B',
        delete_proc = 'MSmerge_del_sp_D6E4E45B646442AC5FF3F1A665864D7B'
    where artid = 'D6E4E45B-6464-42AC-B69C-D1829FE51344' and pubid = '5FF3F1A6-6586-4D7B-ACF5-B25994FEB800'

go

	if object_id('sp_MSpostapplyscript_forsubscriberprocs','P') is not NULL
		exec sys.sp_MSpostapplyscript_forsubscriberprocs @procsuffix = 'D6E4E45B646442AC5FF3F1A665864D7B'

go
