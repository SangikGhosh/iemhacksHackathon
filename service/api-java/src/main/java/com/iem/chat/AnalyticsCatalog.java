package com.iem.chat;

import java.util.List;
import java.util.Map;

public final class AnalyticsCatalog {

    private AnalyticsCatalog() {
    }

    public enum Dimension {
        NONE,
        DAY,
        ROLE,
        STATUS,
        MATERIAL,
        BIN,
        MUNICIPALITY
    }

    public record Metric(String key,
                         String description,
                         String from,
                         String aggregate,
                         String dateColumn,
                         String municipalityColumn,
                         String where,
                         Map<Dimension, String> dimensions) {
    }

    private static final String USERS_JOIN = " join users u on u.id = ";
    private static final String MUNI_JOIN = " left join municipalities mn on mn.id = ";

    public static final Map<String, Metric> METRICS = Map.ofEntries(
            Map.entry("scans", new Metric(
                    "scans",
                    "Number of waste scans uploaded",
                    "detections d" + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.ROLE, "u.role",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("objects_detected", new Metric(
                    "objects_detected",
                    "Total waste objects recognised across all scans",
                    "detections d" + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(d.total_objects), 0)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("carbon_kg", new Metric(
                    "carbon_kg",
                    "Carbon saved in kg from scanned recyclables",
                    "detections d" + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(d.carbon_saved_kg), 0)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("pickups", new Metric(
                    "pickups",
                    "Number of pickup requests raised",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "count(*)",
                    "p.created_at",
                    "p.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', p.created_at)",
                            Dimension.STATUS, "p.status",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("pickups_completed", new Metric(
                    "pickups_completed",
                    "Number of pickups completed by a collector",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "count(*)",
                    "p.completed_at",
                    "p.municipality_id",
                    "p.status = 'COMPLETED'",
                    Map.of(Dimension.DAY, "date_trunc('day', p.completed_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("pickups_cancelled", new Metric(
                    "pickups_cancelled",
                    "Number of pickups cancelled",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "count(*)",
                    "p.cancelled_at",
                    "p.municipality_id",
                    "p.status = 'CANCELLED'",
                    Map.of(Dimension.DAY, "date_trunc('day', p.cancelled_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("waste_kg", new Metric(
                    "waste_kg",
                    "Waste diverted in kg from completed pickups",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "coalesce(sum(coalesce(p.final_weight_kg, p.estimated_weight_kg)), 0)",
                    "p.completed_at",
                    "p.municipality_id",
                    "p.status = 'COMPLETED'",
                    Map.of(Dimension.DAY, "date_trunc('day', p.completed_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("payout", new Metric(
                    "payout",
                    "Money paid to citizens for completed pickups, in INR",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "coalesce(sum(coalesce(p.final_amount, p.estimated_offer)), 0)",
                    "p.completed_at",
                    "p.municipality_id",
                    "p.status = 'COMPLETED'",
                    Map.of(Dimension.DAY, "date_trunc('day', p.completed_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("points_awarded", new Metric(
                    "points_awarded",
                    "Green Points credited from completed pickups",
                    "pickups p" + MUNI_JOIN + "p.municipality_id",
                    "coalesce(sum(p.reward_points), 0)",
                    "p.completed_at",
                    "p.municipality_id",
                    "p.status = 'COMPLETED' and p.reward_awarded = true",
                    Map.of(Dimension.DAY, "date_trunc('day', p.completed_at)",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("new_users", new Metric(
                    "new_users",
                    "Accounts registered during the period. For how many accounts exist in total "
                            + "right now, use get_operations_snapshot instead",
                    "users u" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "u.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', u.created_at)",
                            Dimension.ROLE, "u.role",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("listings_created", new Metric(
                    "listings_created",
                    "Marketplace listings put up for sale",
                    "listings l" + USERS_JOIN + "l.seller_id" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "l.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', l.created_at)",
                            Dimension.STATUS, "l.status",
                            Dimension.MATERIAL, "l.material",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("listings_sold", new Metric(
                    "listings_sold",
                    "Marketplace listings bought by a recycler",
                    "listings l" + USERS_JOIN + "l.seller_id" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "l.sold_at",
                    "u.municipality_id",
                    "l.status = 'SOLD'",
                    Map.of(Dimension.DAY, "date_trunc('day', l.sold_at)",
                            Dimension.MATERIAL, "l.material",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("traded_value", new Metric(
                    "traded_value",
                    "Total marketplace turnover in INR",
                    "listings l" + USERS_JOIN + "l.seller_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(l.price), 0)",
                    "l.sold_at",
                    "u.municipality_id",
                    "l.status = 'SOLD'",
                    Map.of(Dimension.DAY, "date_trunc('day', l.sold_at)",
                            Dimension.MATERIAL, "l.material",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("transactions", new Metric(
                    "transactions",
                    "Wallet transactions recorded",
                    "wallet_transactions t" + USERS_JOIN + "t.user_id" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "t.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', t.created_at)",
                            Dimension.ROLE, "u.role",
                            Dimension.STATUS, "t.type",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("wallet_credited", new Metric(
                    "wallet_credited",
                    "Money credited into wallets in INR",
                    "wallet_transactions t" + USERS_JOIN + "t.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(t.amount), 0)",
                    "t.created_at",
                    "u.municipality_id",
                    "t.type = 'CREDIT'",
                    Map.of(Dimension.DAY, "date_trunc('day', t.created_at)",
                            Dimension.ROLE, "u.role",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("wallet_debited", new Metric(
                    "wallet_debited",
                    "Money debited from wallets in INR",
                    "wallet_transactions t" + USERS_JOIN + "t.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(t.amount), 0)",
                    "t.created_at",
                    "u.municipality_id",
                    "t.type = 'DEBIT'",
                    Map.of(Dimension.DAY, "date_trunc('day', t.created_at)",
                            Dimension.ROLE, "u.role",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("materials_detected", new Metric(
                    "materials_detected",
                    "Material rows recognised, the metric to use for material or bin breakdowns",
                    "detection_materials dm join detections d on d.id = dm.detection_id"
                            + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "count(*)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.MATERIAL, "dm.material",
                            Dimension.BIN, "dm.bin_colour",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("material_weight_kg", new Metric(
                    "material_weight_kg",
                    "Estimated weight in kg of recognised materials, splittable by material or bin",
                    "detection_materials dm join detections d on d.id = dm.detection_id"
                            + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(dm.estimated_weight_kg), 0)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.MATERIAL, "dm.material",
                            Dimension.BIN, "dm.bin_colour",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')"))),

            Map.entry("material_value", new Metric(
                    "material_value",
                    "Estimated scrap value in INR of recognised materials",
                    "detection_materials dm join detections d on d.id = dm.detection_id"
                            + USERS_JOIN + "d.user_id" + MUNI_JOIN + "u.municipality_id",
                    "coalesce(sum(dm.estimated_value), 0)",
                    "d.created_at",
                    "u.municipality_id",
                    null,
                    Map.of(Dimension.DAY, "date_trunc('day', d.created_at)",
                            Dimension.MATERIAL, "dm.material",
                            Dimension.BIN, "dm.bin_colour",
                            Dimension.MUNICIPALITY, "coalesce(mn.name, 'Unassigned')")))
    );

    public static List<String> metricKeys() {
        return METRICS.keySet().stream().sorted().toList();
    }

    public static String describe() {
        return METRICS.values().stream()
                .sorted((a, b) -> a.key().compareTo(b.key()))
                .map(m -> m.key() + " = " + m.description())
                .reduce((a, b) -> a + "; " + b)
                .orElse("");
    }
}
