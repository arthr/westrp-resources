---@class vorp_billing_translation
local Translation = {}

Translation.Langs = {
    English = {
        MenuLabels = {
            menu_title     = "Billing Menu",
            submenu_text   = "SubMenu",
            player_id      = "Player ID",
            player_id_desc = "The ID of the player you want to bill",
            bill_reason    = "Bill Reason",
            reason_desc    = "The reason for the bill",
            bill_amount    = "Bill Amount",
            amount_desc    = "The amount of money to bill",
            confirm        = "Confirm",
            confirm_desc   = "Submit the bill",
            menu_input     = "Type Here"
        },

        Notifications = {
            fill_all_fields     = "Please fill in all fields",
            not_allowed_command = "You are not allowed to use this command",
            not_on_duty         = "You are not on duty",
            not_allowed_bill    = "You are not allowed to bill",
            self_billing_error  = "You cannot bill yourself",
            target_not_found    = "Target not found, you can't bill players that are not online",
            target_too_far      = "Target is too far away from you",
            max_bill_exceeded   = "You cannot bill more than ",
            bill_successful     = "You have successfully billed",
            bill_received       = "You have been billed for ",
            insufficient_funds  = "Player doesn't have enough money to pay the bill",
            For                 = "for",
        },

        ReceiptInfo = {
            receipt_description = "This is a bill you received",
            billed_by           = "Billed By",
            date                = "Date",
            reason              = "Reason",
            Ammount             = "Amount",
        },

        InputInfo = {
            only_numbers_allowed = "Only Numbers Are Allowed",
            only_letters_allowed = "Only Letters Are Allowed",
            Added                = "Added ID: ",
        }
    },
    Portuguese = {
        MenuLabels = {
            menu_title     = "Menu de Fatura",
            submenu_text   = "SubMenu",
            player_id      = "ID do Jogador",
            player_id_desc = "O ID do jogador que você deseja faturar",
            bill_reason    = "Motivo da Fatura",
            reason_desc    = "O motivo da fatura",
            bill_amount    = "Valor da Fatura",
            amount_desc    = "O valor do dinheiro a ser faturado",
            confirm        = "Confirmar",
            confirm_desc   = "Enviar a fatura",
            menu_input     = "Digite Aqui"
        },
        Notifications = {
            fill_all_fields     = "Preencha todos os campos",
            not_allowed_command = "Você não tem permissão para usar este comando",
            not_on_duty         = "Você não está de serviço",
            not_allowed_bill    = "Você não tem permissão para faturar",
            self_billing_error  = "Você não pode faturar a si mesmo",
            target_not_found    = "Alvo não encontrado, você não pode faturar jogadores que não estão online",
            target_too_far      = "O alvo está muito longe de você",
            max_bill_exceeded   = "Você não pode faturar mais do que ",
            bill_successful     = "Você faturou com sucesso",
            bill_received       = "Você foi faturado por ",
            insufficient_funds  = "O jogador não tem dinheiro suficiente para pagar a fatura",
            For                 = "por",
        },
        ReceiptInfo = {
            receipt_description = "Esta é uma fatura que você recebeu",
            billed_by           = "Faturado Por",
            date                = "Data",
            reason              = "Motivo",
            Ammount             = "Valor",
        },
        InputInfo = {
            only_numbers_allowed = "Somente Números São Permitidos",
            only_letters_allowed = "Somente Letras São Permitidas",
            Added                = "ID Adicionado: ",
        }
    }
}

return {
    Translation = Translation
}
