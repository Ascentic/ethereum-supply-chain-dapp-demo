var web3Instance;
const PRODUCER_ADDRESS = "0xA74F469E02A8fC56B7490F8A846CA90434eDD013";
const CUSTOMER_ADDRESS = "0x499c0eebAee7f50a20686a5faE0A48478BE5f1c1";
const TRANSPORTER_ADDRESS = "0x00a1449529cc8F694cC1021622Fef9e8cEF46916";
const MESSAGE_TYPE = {
  Success: 1,
  Error: -1,
};
App = {
  contracts: {},

  load: async () => {
    await App.loadWeb3();
    await App.loadContract();
  },

  loadWeb3: async () => {
    if (window.ethereum) {
      web3Instance = new Web3(window.ethereum);
      console.log(web3Instance.currentProvider);
      await window.ethereum.enable();
    } else if (window.web3) {
      web3Instance = new Web3(window.web3.currentProvider);
    } else {
      window.alert(
        "Non-Ethereum browser detected. Please install MetaMask plugin"
      );
    }
  },

  loadContract: async () => {
    // Create a JavaScript version of the smart contract
    const vaccineTransport = await $.getJSON("SupplyChain.json");
    App.contracts.VaccineTransport = TruffleContract(vaccineTransport);
    App.contracts.VaccineTransport.setProvider(web3Instance.currentProvider);

    // Hydrate the smart contract with values from the blockchain
    App.vaccineTransport = await App.contracts.VaccineTransport.deployed();
  },

  createOrder: async (noOfvaccines, leadTime, penaltyRate) => {
    try {
      var result = await App.vaccineTransport.createOrder(
        PRODUCER_ADDRESS,
        noOfvaccines,
        leadTime,
        penaltyRate,
        {
          from: CUSTOMER_ADDRESS,
        }
      );

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  getOrder: async (orderId) => {
    var order = await App.vaccineTransport.getOrder(orderId);

    return order;
  },

  quoteVaccinePrice: async (orderId, price, temp, maxAllowed) => {
    try {
      var result = await App.vaccineTransport.quotePrice(
        orderId,
        price,
        temp,
        maxAllowed,
        {
          from: PRODUCER_ADDRESS,
        }
      );

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  quoteTransport: async (orderId, price) => {
    try {
      var result = await App.vaccineTransport.quoteTransport(orderId, price, {
        from: TRANSPORTER_ADDRESS,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  confirmOrderCustomer: async (orderId, total) => {
    try {
      var val = web3Instance.utils.toWei(total, "ether");
      var result = await App.vaccineTransport.confirmOrder(orderId, {
        from: CUSTOMER_ADDRESS,
        value: val,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  confirmOrderTransporter: async (orderId, vaccineCost) => {
    try {
      var val = web3Instance.utils.toWei(vaccineCost, "ether");
      var result = await App.vaccineTransport.confirmTransporter(orderId, {
        from: TRANSPORTER_ADDRESS,
        value: val,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  dispatchOrder: async (orderId) => {
    try {
      var result = await App.vaccineTransport.dispatchOrder(orderId, {
        from: PRODUCER_ADDRESS,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  updateTempreture: async (orderId, tempreture) => {
    try {
      var result = await App.vaccineTransport.updateTempreature(
        orderId,
        tempreture,
        {
          from: TRANSPORTER_ADDRESS,
        }
      );

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  completeOrder: async (orderId, tempreture) => {
    try {
      var result = await App.vaccineTransport.completeOrder(orderId, {
        from: TRANSPORTER_ADDRESS,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },

  receiveOrder: async (orderId) => {
    try {
      var result = await App.vaccineTransport.receiveOrder(orderId, {
        from: CUSTOMER_ADDRESS,
      });

      return result;
    } catch (error) {
      console.log(error.message);
    }
  },
};

$(() => {
  $(window).load(async () => {
    hideMessages();

    await App.load();

    App.vaccineTransport.OrderCreated(function (error, result) {
      if (!error) {
        showMessage(
          MESSAGE_TYPE.Success,
          result.returnValues.message +
            ". Order Id :" +
            result.returnValues.order.orderId
        );
      } else {
        showMessage(MESSAGE_TYPE.Error, error);
      }
    });

    $("button").on("click", () => {
      hideMessages();
    });

    $("#co_create").on("click", async () => {
      await createOrder();
    });

    $(".orderId").on("blur", async (e) => {
      var orderId = $("#" + $(e.target).prop("id")).val();
      await viewOrder(orderId);
    });

    $("#qv_submit").on("click", async () => {
      await quotePrice();
    });

    $("#qt_submit").on("click", async () => {
      await quoteTransport();
    });

    $("#cfo_submit").on("click", async () => {
      await confirmOrder();
    });

    $("#cfot_submit").on("click", async () => {
      await confirmOrderTransporter();
    });

    $("#do_submit").on("click", async () => {
      await dispatchOrder();
    });

    $("#ut_submit").on("click", async () => {
      await updateTempreture();
    });

    $("#cmt_submit").on("click", async () => {
      await completeOrder();
    });

    $("#rc_submit").on("click", async () => {
      await receiveOrder();
    });
  });

  async function createOrder() {
    var result = await App.createOrder(
      $("#co_no_of_vaccines").val(),
      $("#co_lead_time").val(),
      $("#co_penalty_Rate").val()
    );
    if (result.receipt.status) {
      showMessage(MESSAGE_TYPE.Success, "Order Creted Successfully");
    }
  }

  function clearOrder() {
    $("#co_no_of_vaccines").val("");
    $("#co_lead_time").val("");
    $("#co_penalty_Rate").val("");
  }

  async function viewOrder(orderId) {
    var result = await App.getOrder(orderId);
    $("#vo_no_vaccines").val(result.numberOfVaccines);
    $("#vo_lead_time").val(result.maxLeadTime);
    $("#vo_penalty_Rate").val(result.lateDeliveryPanalty);
    $("#vo_customer").val(result.customer);
    $("#vo_producer").val(result.producor);
    $("#vo_trasporter").val(result.transporter);
    $("#vo_rec_temp").val(result.reccomendedTemp);
    $("#vo_max_exeed").val(result.maxExeedAllowed);
    var vaccineCost = web3Instance.utils.fromWei(result.vaccineCost, "ether");
    var transportCost = web3Instance.utils.fromWei(
      result.transportCost,
      "ether"
    );
    var total = web3Instance.utils.fromWei(result.totalAmount, "ether");

    $("#vo_max_vaccine_cost").val(vaccineCost);
    $("#vo_transport_cost").val(transportCost);
    $("#vo_total").val(total);
    $("#vo_order_status").val(getOrderStatus(result.status));
  }

  async function quotePrice() {
    var result = await App.quoteVaccinePrice(
      $("#qv_order_id").val(),
      $("#qv_price").val(),
      $("#qv_rec_temp").val(),
      $("#qv_max_allowed").val()
    );
    if (result.receipt.status) {
      alert("Price added successfully");
    }
  }
  async function quoteTransport() {
    var result = await App.quoteTransport(
      $("#qt_order_id").val(),
      $("#qt_price").val()
    );
    if (result.receipt.status) {
      alert("Price added successfully");
      clearOrder();
    }
  }

  async function confirmOrder() {
    var result = await App.confirmOrder(
      $("#cfo_order_id").val(),
      $("#vo_total").val()
    );
  }
  async function confirmOrderTransporter() {
    var result = await App.confirmOrder(
      $("#cfot_order_id").val(),
      $("#vo_max_vaccine_cost").val()
    );
  }

  async function dispatchOrder() {
    var result = await App.dispatchOrder($("#do_order_id").val());
  }

  async function updateTempreture() {
    var result = await App.updateTempreture(
      $("#ut_order_id").val(),
      $("#ut_tempreture").val()
    );
  }

  async function completeOrder() {
    var result = await App.completeOrder($("#rc_order_id").val());
  }

  async function receiveOrder() {
    var result = await App.receiveOrder($("#rc_order_id").val());
  }

  function getOrderStatus(statusId) {
    switch (statusId) {
      case "0":
        return "REQUESTED";

      case "1":
        return "PRICE_QUOTED";

      case "2":
        return "TRANSPORT_QUOTED";

      case "3":
        return "CUSTOMER_CONFIRMED";

      case "4":
        return "TRANSPORTED_CONFIRMED";

      case "5":
        return "DISPATCHED";

      case "6":
        return "DELIVERED";
      case "7":
        return "ACCEPTED";
      case "8":
        return "REJECTED";

      default:
    }
  }

  function hideMessages() {
    $(".alert").hide();
  }

  function showMessage(type, message) {
    $(".alert").hide();
    if (type == MESSAGE_TYPE.Success) {
      $(".alert-success").show();
      $(".alert-success").html(`<p>${message}</p>`);
    }
  }
});
