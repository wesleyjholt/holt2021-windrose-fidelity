#!/bin/sh

windrose=NantucketWindRose
turbine_type=VestasV80_2MW
wake_model=GaussYawVariableSpread
opt_algorithm=SnoptWECAlgorithm
boundary_shape=CircleBoundary
initial_layout_path="../data/initial-layouts/circle/${nturbines}turb/${boundary_radius}r/initial-layout-${layout_number}.txt"
final_layout_directory_path="../results/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/"
final_layout_file_name="final-layout-${layout_number}.yaml"
opt_info_directory="../results/opt-info/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/layout-${layout_number}/"
final_layout_figure_directory_path="../results/figures/final-layouts/circle/${nturbines}turb/${boundary_radius}r/${windrose}/${turbine_type}/${wake_model}/${opt_algorithm}/${ndirs}dirs/"
final_layout_figure_file_name="final-layout-${layout_number}.png"
