# frozen_string_literal: true

class LogActivityPresenter
  def self.collection(logs)
    logs.map { |log| as_json(log) }
  end

  def self.as_json(log, detail: false)
    payload = {
      id: log.id,
      timestamp: timestamp(log),
      timestamp_date: log.created_at&.strftime("%d/%m/%Y"),
      timestamp_time: log.created_at&.strftime("%H:%M"),
      admin: {
        id: log.admin_id,
        full_name: log.admin&.full_name,
      },
      admin_name: log.admin&.full_name,
      action: log.action,
      action_label: action_label(log.action),
      action_badge_color: action_badge_color(log.action),
      module_name: log.module_name,
      module_page: module_page(log.module_name),
      description: summary_description(log),
      created_at: log.created_at&.iso8601,
      updated_at: log.updated_at&.iso8601,
    }

    return payload unless detail

    payload.merge(
      description_detail: localized_description(log.description),
      description_raw: log.description,
    )
  end

  def self.timestamp(log)
    log.created_at&.strftime("%d/%m/%Y, %H:%M")
  end

  def self.module_page(value)
    map = {
      "Financial" => "Transaction",
    }

    map.fetch(value.to_s, value.to_s)
  end

  def self.action_label(value)
    value.to_s.capitalize
  end

  def self.action_badge_color(value)
    map = {
      "create" => "blue",
      "update" => "orange",
      "delete" => "red",
    }

    map.fetch(value.to_s.downcase, "gray")
  end

  def self.localized_description(raw_value)
    raw = raw_value.to_s
    return raw if raw.blank?

    case raw
    when /\ACreated communication #(\d+)\z/i
      "Membuat komunikasi ##{Regexp.last_match(1)}"
    when /\AUpdated communication #(\d+)\z/i
      "Memperbarui komunikasi ##{Regexp.last_match(1)}"
    when /\ADeleted communication #(\d+)\z/i
      "Menghapus komunikasi ##{Regexp.last_match(1)}"
    when /\ACreated financial transaction #(\d+)\z/i
      "Membuat transaksi keuangan ##{Regexp.last_match(1)}"
    when /\AUpdated financial transaction #(\d+)\z/i
      "Memperbarui transaksi keuangan ##{Regexp.last_match(1)}"
    when /\ADeleted financial transaction #(\d+)\z/i
      "Menghapus transaksi keuangan ##{Regexp.last_match(1)}"
    when /\ACreated maintenance request #(\d+)\z/i
      "Membuat permintaan maintenance ##{Regexp.last_match(1)}"
    when /\AUpdated maintenance request #(\d+)\z/i
      "Memperbarui permintaan maintenance ##{Regexp.last_match(1)}"
    when /\ADeleted maintenance request #(\d+)\z/i
      "Menghapus permintaan maintenance ##{Regexp.last_match(1)}"
    when /\ACreated property: (.+)\z/i
      "Membuat properti: #{Regexp.last_match(1)}"
    when /\AUpdated property: (.+)\z/i
      "Memperbarui properti: #{Regexp.last_match(1)}"
    when /\ADeleted property: (.+)\z/i
      "Menghapus properti: #{Regexp.last_match(1)}"
    when /\ACreated unit: (.+)\z/i
      "Membuat unit: #{Regexp.last_match(1)}"
    when /\AUpdated unit: (.+)\z/i
      "Memperbarui unit: #{Regexp.last_match(1)}"
    when /\ADeleted unit: (.+)\z/i
      "Menghapus unit: #{Regexp.last_match(1)}"
    when /\ACreated payment (.+)\z/i
      "Membuat pembayaran #{Regexp.last_match(1)}"
    when /\AUpdated payment (.+)\z/i
      "Memperbarui pembayaran #{Regexp.last_match(1)}"
    when /\ADeleted payment (.+)\z/i
      "Menghapus pembayaran #{Regexp.last_match(1)}"
    when /\APushed payment (.+) to Xendit\z/i
      "Mengirim pembayaran #{Regexp.last_match(1)} ke Xendit"
    when /\ACreated (admin|owner|tenant) user: (.+)\z/i
      "Membuat user #{Regexp.last_match(1)}: #{Regexp.last_match(2)}"
    when /\AUpdated user: (.+)\z/i
      "Memperbarui user: #{Regexp.last_match(1)}"
    when /\ADeleted user: (.+)\z/i
      "Menghapus user: #{Regexp.last_match(1)}"
    else
      raw
    end
  end

  def self.summary_description(log)
    raw = log.description.to_s
    return "Mengirim pembayaran ke Xendit" if pushed_payment?(raw)

    "#{action_verb(log.action)} #{summary_target(log.module_name)}"
  end

  def self.pushed_payment?(raw_value)
    /\APushed payment (.+) to Xendit\z/i.match?(raw_value.to_s)
  end

  def self.action_verb(action)
    map = {
      "create" => "Membuat",
      "update" => "Memperbarui",
      "delete" => "Menghapus",
    }

    map.fetch(action.to_s.downcase, action.to_s.humanize)
  end

  def self.summary_target(module_name)
    map = {
      "Communication" => "komunikasi",
      "Financial" => "transaksi",
      "Maintenance" => "maintenance",
      "Property" => "properti",
      "Unit" => "unit",
      "Payment" => "pembayaran",
      "User" => "pengguna",
      "Auth" => "autentikasi",
      "LogActivity" => "log aktivitas",
    }

    map.fetch(module_name.to_s, module_name.to_s.downcase)
  end
end
