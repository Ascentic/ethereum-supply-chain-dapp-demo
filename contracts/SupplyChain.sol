// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract SupplyChain {
    constructor() public {
        createEntities();
    }

    struct Manufacturer {
        address payable account;
        string name;
        uint256 balance;
    }

    struct Customer {
        address payable account;
        string name;
        uint256 balance;
    }

    struct Transporter {
        address payable account;
        string name;
        uint256 balance;
    }

    enum OrderStatus {
        REQUESTED,
        PRICE_QUOTED,
        TRANSPORT_QUOTED,
        CUSTOMER_CONFIRMED,
        TRANSPORTED_CONFIRMED,
        DISPATCHED,
        DELIVERED,
        ACCEPTED,
        REJECTED
    }

    struct Order {
        uint256 orderId;
        address payable manufacturer;
        address payable customer;
        address payable transporter;
        uint256 orderdAt;
        uint256 customerConfirmedAt;
        uint256 transporterConfirmedAt;
        uint256 maxLeadTime;
        uint256 deliveredAt;
        int256 reccomendedTemp;
        uint256 maxExeedAllowed;
        uint256 numberOfVaccines;
        uint256 vaccineCost;
        uint256 totalAmount;
        uint256 transportCost;
        uint256 lateDeliveryPanalty;
        int256[] tempreture;
        OrderStatus status;
    }

    mapping(address => Manufacturer) internal manufacturers;
    mapping(address => Customer) internal customers;
    mapping(address => Transporter) internal transportes;
    mapping(uint256 => Order) internal orders;
    uint256 nextOrderId = 0;

    event OrderCreated(address from, Order order, string message);

    event OrderRejected(Order order, string message);

    event OrderAccepted(Order order, string message);

    function createEntities() internal {
        Manufacturer memory prod =
            Manufacturer(
                0xA74F469E02A8fC56B7490F8A846CA90434eDD013,
                "Pfizer",
                0
            );
        manufacturers[prod.account] = prod;

        Customer memory customer =
            Customer(
                0x499c0eebAee7f50a20686a5faE0A48478BE5f1c1,
                "Sri Lanka Govenrment",
                0
            );
        customers[customer.account] = customer;

        Transporter memory transporter =
            Transporter(0x00a1449529cc8F694cC1021622Fef9e8cEF46916, "DHL", 0);
        transportes[transporter.account] = transporter;
    }

    function createOrder(
        address payable manufacturer,
        uint256 numberOfVacines,
        uint256 leadTime,
        uint256 latePenalty
    ) public {
        require(
            customers[msg.sender].account == msg.sender,
            "Invalid customer"
        );
        require(
            manufacturers[manufacturer].account == manufacturer,
            "Invalid Manufacturer"
        );
        require(
            numberOfVacines > 0,
            "Number of vaccines should be greater than 0"
        );

        nextOrderId++;
        Order memory order;
        order.orderId = nextOrderId;
        order.customer = msg.sender;
        order.manufacturer = manufacturer;
        order.orderdAt = block.timestamp;
        order.numberOfVaccines = numberOfVacines;
        order.maxLeadTime = leadTime;
        order.maxExeedAllowed = 5;
        order.lateDeliveryPanalty = latePenalty;
        order.status = OrderStatus.REQUESTED;
        orders[nextOrderId] = order;

        emit OrderCreated(msg.sender, order, "Order successfully created");
    }

    function quotePrice(
        uint256 orderId,
        uint256 price,
        int256 tempreture,
        uint256 maxExeeds
    ) public {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            orderCreated.manufacturer == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.REQUESTED,
            "Price already quoted"
        );
        orderCreated.vaccineCost = price * (1 ether);
        orderCreated.reccomendedTemp = tempreture;
        orderCreated.maxExeedAllowed = maxExeeds;
        orderCreated.status = OrderStatus.PRICE_QUOTED;
    }

    function quoteTransport(uint256 orderId, uint256 price) public {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            transportes[msg.sender].account == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.PRICE_QUOTED,
            "Invalid Order Status"
        );

        orderCreated.transportCost = price * (1 ether);
        orderCreated.transporter = msg.sender;
        orderCreated.totalAmount =
            orderCreated.vaccineCost +
            orderCreated.transportCost;
        orderCreated.status = OrderStatus.TRANSPORT_QUOTED;
    }

    function confirmOrder(uint256 orderId) public payable {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(orderCreated.customer == msg.sender, "Invalid sender account");
        require(
            orderCreated.status == OrderStatus.TRANSPORT_QUOTED,
            "Invalid order Status"
        );
        require(
            msg.value == orderCreated.totalAmount,
            "Total order amount must be deposited in advance"
        );

        orderCreated.customerConfirmedAt = block.timestamp;
        orderCreated.status = OrderStatus.CUSTOMER_CONFIRMED;
        customers[msg.sender].balance = msg.value;
    }

    function confirmTransporter(uint256 orderId) public payable {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            orderCreated.transporter == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.CUSTOMER_CONFIRMED,
            "Invalid order Status"
        );
        require(
            msg.value == orderCreated.vaccineCost,
            "Transporter should have deposited the cost of vaccines to recover the lost"
        );

        orderCreated.transporterConfirmedAt = block.timestamp;
        orderCreated.status = OrderStatus.TRANSPORTED_CONFIRMED;
        customers[msg.sender].balance = msg.value;
    }

    function dispatchOrder(uint256 orderId) public payable {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            orderCreated.manufacturer == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.TRANSPORTED_CONFIRMED,
            "Invalid order Status"
        );

        orderCreated.status = OrderStatus.DISPATCHED;
    }

    function updateTempreature(uint256 orderId, int256 temp) public {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            orderCreated.transporter == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.DISPATCHED,
            "Invalid order Status"
        );
        orderCreated.tempreture.push(temp);
    }

    function completeOrder(uint256 orderId) public {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(
            orderCreated.transporter == msg.sender,
            "Invalid sender account"
        );
        require(
            orderCreated.status == OrderStatus.DISPATCHED,
            "Invalid order Status"
        );
        orderCreated.status = OrderStatus.DELIVERED;
    }

    function receiveOrder(uint256 orderId) public payable {
        Order storage orderCreated = orders[orderId];
        require(orderCreated.orderId > 0, "Invalid Order Id");
        require(orderCreated.customer == msg.sender, "Invalid sender account");
        require(
            orderCreated.status == OrderStatus.DELIVERED,
            "Invalid order Status"
        );

        string memory message;

        //Set delivered time
        orderCreated.deliveredAt = block.timestamp;

        //Check the tempreture
        uint256 exceededTempCount = 0;
        for (uint256 i; i < orderCreated.tempreture.length; i++) {
            if (orderCreated.tempreture[i] > orderCreated.reccomendedTemp) {
                exceededTempCount++;
            }
        }
        //Reject order due to not meeting the tempreture conditions
        if (exceededTempCount > orderCreated.maxExeedAllowed) {
            //Pay back total cost to the customer
            orderCreated.customer.transfer(orderCreated.totalAmount);

            //Pay back cost of vaccines to the producer
            orderCreated.manufacturer.transfer(orderCreated.vaccineCost);
            orderCreated.status = OrderStatus.REJECTED;
            message = "Order rejected due to not meeting reccomended tempreture conditions. Your deposit was refunded";
            emit OrderRejected(orderCreated, message);
            return;
        }

        //Caclulate the lead time
        uint256 timeGap =
            orderCreated.deliveredAt - orderCreated.customerConfirmedAt;
        uint256 timeGapInHours = timeGap / (1000 * 60 * 60);

        uint256 penaltyAmount = 0;
        //Get penalty if applicable
        if (timeGapInHours > orderCreated.maxLeadTime) {
            //get penalty from transporter
            penaltyAmount =
                (orderCreated.totalAmount * orderCreated.lateDeliveryPanalty) /
                100;
            orderCreated.customer.transfer(penaltyAmount);

            message = "Order Accepted with penalties. Penalty charges refunded to your accout due to the late delivery.";
        }

        //Pay vaccine cost to the producer
        orderCreated.manufacturer.transfer(orderCreated.vaccineCost);

        //Pay transport cost+ initial deposit to the transporter
        orderCreated.transporter.transfer(
            orderCreated.transportCost +
                transportes[orderCreated.transporter].balance -
                penaltyAmount
        );
        orderCreated.status = OrderStatus.ACCEPTED;
        if (bytes(message).length == 0) {
            message = " Order is accepted..";
        }

        emit OrderAccepted(orderCreated, message);
    }
}
