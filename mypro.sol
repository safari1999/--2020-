pragma solidity ^0.4.24;

import "./Table.sol";

contract mypro{
    //添加用户：返回值，用户名
    event Register(int256 ret, string user, int256 trust);
    //功能一 签发应收账款：返回值，账单号，借出钱的用户，欠钱的用户，欠款总额，还款时间(多少天后)
    event Sign(int256 ret, string bill_id, string lender, string borrower,  uint256  tran_amount, uint256 paytime);
    //功能二 转让应收账款：返回值，分解的账单号，新的账单号，新的借出钱的用户，转让总额
    event Transfer(int256 ret, string pre_bill_id, string new_bill_id, string new_lender, uint256 tran_amount);
    //功能三 向银行融资：返回值，融资用户，融资总额，还款时间
    //event Financing(int256 ret, string user,  uint256 tran_amount, uint256 paytime);
    event Financing(int256 ret);
    //功能四 应收账款支付结算：返回值，账单号，距离借钱日过去的时间（天为单位）
    //event Pay(int256 ret, string bill_id, uint256 lendtime);
    event Pay(int256 temp_pay);

    constructor() public {
        //构造函数中创建表
        createTable();
    }

    function createTable() private {
        TableFactory tf = TableFactory(0x1001); 

        // 资产管理表, key : bill_id, field : lender  borrower  tran_amount  paytime
        // | 账单号(主键) | 借出钱的用户 | 欠钱的用户 |     总额     | 还款时间 |
        // |    bill_id  |   lender    |  borrower  | tran_amount  | paytime  |  
        // 创建表:账单
        tf.createTable("t_bill", "bill_id", "lender,borrower,tran_amount,paytime");
        // 资产管理表, key : user, field :  trust(0不受信用，1受信用)
        // |      用户名(主键)   |   是否受银行信用  |
        // |       user         |      trust       |    
        // 创建表：用户
        tf.createTable("t_user", "user", "trust");
    }

    function openTableUser() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_user");
        return table;
    }    

    function openTableBill() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_bill");
        return table;
    }    

    /*
    根据用户名查询是否受银行信用
    参数 ： user : 用户名
    返回值：参数一： 成功返回0, 账户不存在返回-1     参数二： 第一个参数为0时有效，是否受信用
    */
    function selectAccount(string user) public constant returns(int256, uint256) {
        // 打开表
        Table table = openTableUser();
        // 查询
        Entries entries = table.select(user, table.newCondition());
        uint256 trust = 0;
        if (0 == uint256(entries.size())) {
            return (-1, trust);
        } else {
            Entry entry = entries.get(0);
            return (0, uint256(entry.getInt("trust")));
        }
    }

    /*
    根据账单号查询借出钱的用户、欠钱的用户、总额、还款时间
    参数 ： bill_id : 账单号
    返回值：参数一： 成功返回0, 账户不存在返回-1    参数二： 第一个参数为0时有效，借出钱的用户
            参数三： 第一个参数为0时有效，欠钱的用户   参数四： 第一个参数为0时有效，总额
            参数五： 第一个参数为0时有效，还款时间
    */    
    function selectBill(string bill_id) public constant returns(int256, string, string, uint256, uint256) {
        // 打开表
        Table table = openTableBill();
        // 查询
        Entries entries = table.select(bill_id, table.newCondition());
        //string  storage lender = "0";
        //string storage borrower = "0";
        //uint256 tran_amount = 0;
        //uint256 paytime = 0;
        if (0 == uint256(entries.size())) {
            //return (-1, lender, borrower, tran_amount, paytime);
            return (-1,"0","0",0,0);
        } else {
            Entry entry = entries.get(0);
            //lender = entry.getString("lender");
            //borrower = entry.getString("borrower");
            //tran_amount = entry.getInt("tran_amount");
            //paytime = entry.getInt("paytime");
            return (int256(0), entry.getString("lender"), entry.getString("borrower"), uint256(entry.getInt("tran_amount")), uint256(entry.getInt("paytime")));
        }
    }

    /*
    用户注册
    参数 ： user : 资产账户      trust  : 是否受银行信用
    返回值：0:资产注册成功   -1:资产账户已存在   -2:其他错误
    */
    function registerUser(string user, int256 trust) public returns(int256){
        int256 res = 0;
        int256 temp_check= 0;
        uint256 temp_trust = 0;
        // 查询账户是否存在
        (temp_check, temp_trust) = selectAccount(user);
        if(temp_check != 0) {
            Table table = openTableUser();
            
            Entry entry = table.newEntry();
            entry.set("user", user);
            entry.set("trust", trust);
            // 插入
            int temp_insert = table.insert(user, entry);
            if (temp_insert == 1) {
                // 成功
                res = 0;
            } else {
                // 失败? 无权限或者其他错误
                res = -2;
            }
        } else {
            // 账户已存在
            res = -1;
        }

        emit Register(res, user, trust);
        return res;
    }


    /*
    event Sign 功能一 签发应收账款：返回值，账单号，借出钱的用户，欠钱的用户，欠款总额，还款时间(多少天后)
    参数 ： bill_id : 账单号   lender  : 借出钱的用户    borrower : 欠钱的用户
           tran_amount : 欠款总额    paytime : 还款时间(多少天后)
    返回值： 0:签发应收账款成功   -2:其他错误
    */
    function issueBill(string bill_id, string lender, string borrower, uint256 tran_amount, uint256 paytime) public returns(int256){
        int256 res = 0;
        int256 temp= 1;

        if(temp != 0) {
            Table table = openTableBill();
            
            Entry entry = table.newEntry();
            entry.set("bill_id", bill_id);
            entry.set("lender", lender);
            entry.set("borrower", borrower);
            entry.set("tran_amount", int(tran_amount));
            entry.set("paytime", int(paytime));

            // 插入
            int temp_insert = table.insert(bill_id, entry);
            if (temp_insert == 1) {
                // 成功
                res = 0;
            } else {
                // 失败? 无权限或者其他错误
                res = -2;
            }
        }

        emit Sign(res, bill_id, lender, borrower, tran_amount, paytime);
        return res;
    }


    /*
    event Transfer 功能二 转让应收账款：返回值，分解的账单号，新的账单号，新的借出钱的用户，转让总额
    参数 ： pre_bill_id : 分解的账单号   new_bill_id ： 新的账单号
            new_lender : 新借出钱的用户   tran_amount : 转让总额
    返回值：0  签发应收账款成功     -2 其他错误
    */
    function transfer(string pre_bill_id, string new_bill_id,string new_lender, uint256 tran_amount) public returns(int256) {
        uint256 pre_amount = 0;

        Table table = openTableBill();

        Entries entry_bt = table.select(pre_bill_id, table.newCondition());
        Entry entry_lender = entry_bt.get(0);
        pre_amount = uint256(entry_lender.getInt("tran_amount"));
    //(int256(0), entry.getString("lender"), entry.getString("borrower"), uint256(entry.getInt("tran_amount")), uint256(entry.getInt("paytime")));

        Entry entry0 = table.newEntry();
        entry0.set("bill_id", pre_bill_id);
        entry0.set("lender", entry_lender.getString("lender"));
        entry0.set("borrower", entry_lender.getString("borrower"));
        entry0.set("tran_amount", int256(pre_amount - tran_amount));
        entry0.set("paytime", int256(entry_lender.getInt("paytime")));

        // 更新被分解的账单
        int temp_insert = table.update(pre_bill_id, entry0, table.newCondition());
        if(temp_insert != 1) {
            // 失败? 无权限或者其他错误?
            emit Transfer(-2, pre_bill_id, new_bill_id, new_lender, tran_amount);
            return -2;
        }

        Entry entry1 = table.newEntry();
        entry1.set("bill_id", new_bill_id);
        entry1.set("lender", new_lender);
        entry1.set("borrower", entry_lender.getString("borrower"));
        entry1.set("tran_amount", int256(tran_amount));
        entry1.set("paytime", int256(entry_lender.getInt("paytime")));

        // 插入新账单
        int temp_insert2 = table.insert(new_bill_id, entry1);


        emit Transfer(0, pre_bill_id, new_bill_id, new_lender, tran_amount);
        return 0;
    }



    /* 
    event Financing  功能三 向银行融资：返回值，融资用户，融资总额，还款时间
        参数 ： pre_bill_id : 分解的账单号  new_bill_id ： 新的账单号   tran_amount : 转让总额
        返回值： 0 银行融资成功   -1 欠款方的账单不受信用，银行不融资   -2 其他问题，融资失败
    */
    function fiancing(string pre_bill_id, string new_bill_id, uint256 tran_amount) public returns(int256) {
        Table table0 = openTableBill();
        Table table1 = openTableUser();
        Entries entry_bt = table0.select(pre_bill_id, table0.newCondition());
        Entry entry_lender = entry_bt.get(0);
        
        Entries entry_ut = table1.select(entry_lender.getString("borrower"), table1.newCondition());
        Entry entry_trust = entry_ut.get(0);

        //1为受信用
        if(entry_trust.getInt("trust")==int256(0)){
            emit Financing(-1);
            return -1;
        }

        if(entry_trust.getInt("trust")==int256(1)){
            transfer(pre_bill_id, new_bill_id,"bank",tran_amount);
            emit Financing(0);
            return 0;
        }

        emit Financing(-2);
        return -2;
    }


    /*
    event Pay  功能四 应收账款支付结算：返回值，账单号，距离借钱日过去的时间（单位:天）
    参数 ： bill_id : 账单号    lendtime ： 距离借钱日过去的时间
    */

    function pay(string bill_id, uint256 lendtime) public returns(int){
        Table table = openTableBill();

        Condition condition = table.newCondition();
        condition.EQ("bill_id", bill_id);
        condition.LE("paytime", int256(lendtime));
        
        int temp_pay = table.remove(bill_id, condition);

        emit Pay(temp_pay);
        return temp_pay;
    }

}
